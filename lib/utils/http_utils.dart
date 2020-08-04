import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:dio/dio.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/xml_util.dart';

import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/utils/sp_helper.dart';

/// 网络请求数据
class HttpUtils {
  static Future<List<CategoryModel>> getCategoryList() async {
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "list"};

      Response response = await Dio().get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      return XmlUtil.parseCategoryList(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.toString());
    }
    return [];
  }

  static Future<List<VideoModel>> getVideoList({int pageNum = 1, String type, String keyword, String ids}) async {
    List<VideoModel> videos = [];
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "videolist"};

      if (pageNum != null) {
        params["pg"] = pageNum;
      }
      if (type != null && type.isNotEmpty) {
        params["t"] = type;
      }
      if (keyword != null) {
        params["ac"] = "list";
        params["wd"] = keyword;
      }
      if (ids != null) {
        params["ids"] = ids;
      }
      Response response = await Dio().get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      return XmlUtil.parseVideoList(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.toString());
    }
    return videos;
  }

  static Future<VideoModel> getVideoById(String id) async {
    VideoModel video;
    try {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      SourceModel currentSource = SourceModel.fromJson(sourceJson);
      Map<String, dynamic> params = {"ac": "videolist"};
      params["ids"] = id;

      Response response = await Dio().get(currentSource.httpsApi, queryParameters: params);
      String xmlStr = response.data.toString();
      return XmlUtil.parseVideo(xmlStr);
    } catch (e, s) {
      print(s);
      BotToast.showText(text: e.toString());
    }
    return video;
  }
}
