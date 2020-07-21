import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import 'package:v_player/pages/main_page.dart';

Handler mainHandle = Handler(
    handlerFunc: (BuildContext context, Map<String, List<String>> params) {
  return MainPage();
});
