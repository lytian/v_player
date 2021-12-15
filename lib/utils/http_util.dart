import 'dart:async';
import 'dart:convert';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/xml_util.dart';

import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/utils/sp_helper.dart';

/// 网络请求数据
class HttpUtil {
  static HttpUtil? _instance;
  factory HttpUtil() =>_getInstance();
  static late Dio dio;

  HttpUtil._();

  static HttpUtil _getInstance() {
    if (_instance == null) {
      _instance = HttpUtil._();
      _instance!._initDio();
      SpHelper.getInstance();
    }
    return _instance!;
  }

  _initDio() {
    dio = Dio();

    dio.interceptors.add(InterceptorsWrapper(
      onRequest:(RequestOptions options, RequestInterceptorHandler handler) {
        // 动态获取接口Api
        SourceModel currentSource = SourceModel.fromJson(SpHelper.getObject(Constant.key_current_source) as Map<String, dynamic>);
        options.baseUrl = currentSource.httpApi!;
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
      }
    ));
  }

  bool isXml(String data) => data.startsWith('<?xml');

  ///
  /// 获取分类列表
  ///
  Future<List<CategoryModel>> getCategoryList() async {
    Map<String, dynamic> params = {"ac": "list"};
    Response response = await dio.get('', queryParameters: params);
    String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseCategoryList(res);
      } else {
        var data = json.decode(res);
        return (data['class'] as List).map((e) => CategoryModel.fromJson(e)).toList();
      }
    } catch (e, s) {
      print(s);
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
    Map<String, dynamic> params = {
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
    Response response = await dio.get(api ?? '', queryParameters: params);
    String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseVideoList(res);
      } else {
        var data = json.decode(res);
        var list = data['list'] ?? data['data'];
        if (list != null) {
          return (list as List).map((e) => VideoModel.fromJson(e)).toList();
        }
      }
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.toString());
    }
    return [];
  }

  ///
  /// 根据ID获取视频
  ///
  Future<VideoModel?> getVideoById(String id, [ String? baseUrl ]) async {
    Map<String, dynamic> params = {
      "ac": "videolist",
      "ids": id,
    };
    Response response = await dio.get(baseUrl ?? '', queryParameters: params);
    String res = response.data.toString();
    try {
      if (isXml(res)) {
        return XmlUtil.parseVideo(res);
      } else {
        var data = json.decode(res);
        var list = data['list'] ?? data['data'];
        if (list != null) {
          return (list as List).map((e) {
            VideoModel model = VideoModel.fromJson(e);
            // 处理选集
            String? playUrl = e['vpath'] ?? e['vod_play_url'];
            List<Anthology> anthologies = [];
            if (playUrl != null) {
              playUrl.split('#').forEach((s) {
                if (s.indexOf('\$') > -1) {
                  anthologies.add(Anthology(name: s.split('\$')[0], url: s.split('\$')[1]));
                } else {
                  anthologies.add(Anthology(name: null, url: s));
                }
              });
            }
            model.anthologies = anthologies;
            return model;
          }).toList()[0];
        }
      }
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.toString());
    }
    return null;
  }
}
