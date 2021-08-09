import 'package:flutter/material.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/pages/collection_page.dart';
import 'package:v_player/pages/download_page.dart';
import 'package:v_player/pages/main_page.dart';
import 'package:v_player/pages/play_record_page.dart';
import 'package:v_player/pages/setting_page.dart';
import 'package:v_player/pages/source_form_page.dart';
import 'package:v_player/pages/source_manage_page.dart';
import 'package:v_player/pages/splash_page.dart';
import 'package:v_player/pages/video_detail_page.dart';

class Application {
  /// 全局导航的Key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static final String splashPage = '/splash';
  static final String mainPage = '/main';
  static final String videoDetailPage = '/videoDetail';
  static final String sourceManagePage = '/sourceManage';
  static final String sourceFormPage = '/sourceForm';
  static final String settingPage = '/setting';
  static final String downloadPage = '/download';
  static final String collectionPage = '/collection';
  static final String playRecordPage = '/playRecord';

  static final Map<String, WidgetBuilder> routes = {
    splashPage: (context) => SplashPage(),
    mainPage: (context) => MainPage(),
    videoDetailPage: (context, { arguments }) => VideoDetailPage(
      videoId: arguments['videoId']!,
      api: arguments['api'],
    ),
    sourceManagePage: (context) => SourceManagePage(),
    sourceFormPage: (context, { SourceModel? arguments }) => SourceFormPage(source: arguments,),
    settingPage: (context) => SettingPage(),
    downloadPage: (context) => DownloadPage(),
    collectionPage: (context) => CollectionPage(),
    playRecordPage: (context) => PlayRecordPage(),
  };

  static final RouteFactory generateRoute = (settings) {
    // 路由参数处理
    final Function? pageBuilder = routes[settings.name];
    if (pageBuilder != null) {
      if (settings.arguments != null) {
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => pageBuilder(context, arguments: settings.arguments)
        );
      } else{
        return MaterialPageRoute(
            settings: settings,
            builder: (context) => pageBuilder(context)
        );
      }
    }
    return null;
  };
}