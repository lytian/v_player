import 'package:flutter/material.dart';
import 'package:fluro/fluro.dart';
import './router_handler.dart';

class Routers{
  static String root = '/';
  static String mainPage = '/main';
  static String detailPage = '/detail';
  static String sourceManagePage = '/sourceManage';
  static String settingPage = '/setting';
  static String downloadPage = '/download';
  static String localVideoPage = '/localVideo';
  
  static void configureRouters(Router router){
    router.notFoundHandler = new Handler(
      handlerFunc: (BuildContext context, Map<String,List<String>> params){
        print('错误路由');
        return null;
      }
    );
    router.define(mainPage, handler: mainHandle);
    router.define(detailPage, handler: detailHandle);
    router.define(sourceManagePage, handler: sourceManageHandle);
    router.define(settingPage, handler: settingHandle);
    router.define(downloadPage, handler: downloadHandle);
    router.define(localVideoPage, handler: localVideoHandle);
  }
}