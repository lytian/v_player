import 'package:fluro/fluro.dart';
import './router_handler.dart';

class Routers{
  static String root = '/';
  static String mainPage = '/main';
  static String detailPage = '/detail';
  static String sourceManagePage = '/sourceManage';
  static String settingPage = '/setting';
  static String downloadPage = '/download';
  static String collectionPage = '/collection';
  static String playRecordPage = '/playRecord';
  
  static void configureRouters(FluroRouter router){
    router.notFoundHandler = new Handler(
      handlerFunc: (context, Map<String,List<String>> params){
        print('错误路由');
        return null;
      }
    );
    router.define(mainPage, handler: mainHandle);
    router.define(detailPage, handler: detailHandle);
    router.define(sourceManagePage, handler: sourceManageHandle);
    router.define(settingPage, handler: settingHandle);
    router.define(downloadPage, handler: downloadHandle);
    router.define(collectionPage, handler: collectionHandle);
    router.define(playRecordPage, handler: playRecordHandle);
  }
}