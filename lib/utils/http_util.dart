import 'dart:async';
import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/sp_helper.dart';
import 'package:v_player/utils/xml_util.dart';

/// 网络请求数据
class HttpUtil {
  factory HttpUtil() => _instance;
  HttpUtil._internal() {
    _initDio();
    SpHelper.getInstance();
  }
  static final HttpUtil _instance = HttpUtil._internal();
  static late Dio dio;

  void _initDio() {
    dio = Dio();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest:(RequestOptions options, RequestInterceptorHandler handler) {
        // 动态获取接口Api
        final Map? source = SpHelper.getObject(Constant.keyCurrentSource);
        if (source != null) {
          final SourceModel currentSource = SourceModel.fromJson(source);
          options.baseUrl = currentSource.httpApi!;
        }
        handler.next(options);
      },
      onResponse:(Response response, ResponseInterceptorHandler handler) {
        handler.next(response);
      },
      onError: (DioError e, ErrorInterceptorHandler handler) async {
        String msg = '';
        switch (e.type) {
          case DioErrorType.connectTimeout:
          case DioErrorType.receiveTimeout:
          case DioErrorType.sendTimeout:
            msg = '网络请求超时，请稍后重试';
            break;
          case DioErrorType.response:
            switch (e.response!.statusCode) {
              case 401:
              case 403:
                msg = '没有权限访问';
                break;
              case 404:
                msg = '资源请求地址不存在';
                break;
              case 500:
                msg = '资源服务器异常';
                break;
              case 503:
                msg = '资源服务不可用';
                break;
              default:
                msg = '未知网络错误';
                break;
            }
            break;
          default:
            if (e.message.contains('Network is unreachable')) {
              msg = '网络无法访问！';
            } else {
              msg = e.message;
            }
            break;
        }
        BotToast.showText(text: msg);
        handler.next(e);
      },
    ),);
  }

  bool isXml(String data) => data.startsWith('<?xml');

  ///
  /// 获取分类列表
  ///
  Future<List<CategoryModel>> getCategoryList() async {
    final Map<String, String> params = { 'ac': 'list' };
    final Response response = await dio.get<dynamic>('', queryParameters: params);
    final String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseCategoryList(res);
      } else {
        final dynamic data = json.decode(res);
        return (data['class'] as List).map((dynamic e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e) {
      BotToast.showText(text: e.toString());
    }
    return [];
  }

  ///
  /// 获取视频列表
  ///
  Future<List<VideoModel>> getVideoList({
    String? api,
    int pageNum = 1,
    String? type,
    String? keyword,
    String? ids,
    int? hour,
  }) async {
    final Map<String, Object> params = {
      "ac": "videolist",
      "pg": pageNum,
    };

    if (type != null && type.isNotEmpty) {
      params["t"] = type;
    }
    if (keyword != null) {
      params["wd"] = keyword;
    }
    if (ids != null) {
      params["ids"] = ids;
    }
    if (hour != null) {
      params["h"] = hour;
    }
    final Response response = await dio.get<dynamic>(api ?? '', queryParameters: params);
    final String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseVideoList(res);
      } else {
        final dynamic data = json.decode(res);
        final dynamic list = data['list'] ?? data['data'];
        if (list != null) {
          return (list as List).map((dynamic e) => VideoModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      BotToast.showText(text: e.toString());
    }
    return [];
  }

  ///
  /// 根据ID获取视频
  ///
  Future<VideoModel?> getVideoById(String id, [ String? baseUrl ]) async {
    final Map<String, Object> params = {
      "ac": "videolist",
      "ids": id,
    };
    final Response response = await dio.get<dynamic>(baseUrl ?? '', queryParameters: params);
    final String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseVideo(res);
      } else {
        final dynamic data = json.decode(res);
        final dynamic list = data['list'] ?? data['data'];
        if (list != null) {
          return (list as List).map((dynamic e) {
            final VideoModel model = VideoModel.fromJson(e);
            // 处理选集
            final String? playUrl = (e['vpath'] ?? e['vod_play_url']) as String?;
            final List<Anthology> anthologies = [];
            if (playUrl != null) {
              playUrl.split('#').forEach((s) {
                if (s.contains('\$')) {
                  anthologies.add(Anthology(name: s.split('\$')[0], url: s.split('\$')[1]));
                } else {
                  anthologies.add(Anthology(url: s));
                }
              });
            }
            model.anthologies = anthologies;
            return model;
          }).toList()[0];
        }
      }
    } catch (e) {
      BotToast.showText(text: e.toString());
    }
    return null;
  }
}
