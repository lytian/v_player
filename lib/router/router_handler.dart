import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import 'package:v_player/pages/main_page.dart';
import 'package:v_player/pages/video_detail_page.dart';
import 'package:v_player/utils/fluro_convert_util.dart';

Handler mainHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MainPage();
});

Handler detailHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
      String videoId = params['id']?.first;
      String name = params['name']?.first;
      return VideoDetailPage(videoId: videoId, name: FluroConvertUtils.fluroCnParamsDecode(name));
  });