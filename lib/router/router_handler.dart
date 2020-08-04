import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import 'package:v_player/pages/download_page.dart';
import 'package:v_player/pages/local_video_page.dart';
import 'package:v_player/pages/main_page.dart';
import 'package:v_player/pages/setting_page.dart';
import 'package:v_player/pages/source_manage_page.dart';
import 'package:v_player/pages/video_detail_page.dart';
import 'package:v_player/utils/fluro_convert_util.dart';

Handler mainHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MainPage();
});

Handler detailHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  String videoId = params['id']?.first;
  return VideoDetailPage(videoId);
});

Handler sourceManageHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return SourceManagePage();
});

Handler settingHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return SettingPage();
});

Handler downloadHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      return DownloadPage();
    });

Handler localVideoHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      String url = params['url']?.first;
      String name = params['name']?.first;
      return LocalVideoPage(url: FluroConvertUtils.fluroCnParamsDecode(url), name: FluroConvertUtils.fluroCnParamsDecode(name),);
    });