import 'package:flutter/material.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/pages/collection_page.dart';
import 'package:v_player/pages/download_page.dart';
import 'package:v_player/pages/local_video_page.dart';
import 'package:v_player/pages/main_page.dart';
import 'package:v_player/pages/play_record_page.dart';
import 'package:v_player/pages/search_page.dart';
import 'package:v_player/pages/setting_page.dart';
import 'package:v_player/pages/source_form_page.dart';
import 'package:v_player/pages/source_manage_page.dart';
import 'package:v_player/pages/splash_page.dart';
import 'package:v_player/pages/video_detail_page.dart';

mixin Application {
  /// 全局导航的Key
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static const String splashPage = '/splash';
  static const String mainPage = '/main';
  static const String videoDetailPage = '/videoDetail';
  static const String sourceManagePage = '/sourceManage';
  static const String sourceFormPage = '/sourceForm';
  static const String settingPage = '/setting';
  static const String downloadPage = '/download';
  static const String localVideoPage = '/localVideo';
  static const String collectionPage = '/collection';
  static const String playRecordPage = '/playRecord';
  static const String searchPage = '/search';

  static final Map<String, WidgetBuilder> routes = {
    splashPage: (context) => const SplashPage(),
    mainPage: (context) => const MainPage(),
    videoDetailPage: (context, { dynamic arguments }) => VideoDetailPage(
      videoId: arguments['videoId'] as String,
      api: arguments['api'] as String?,
    ),
    sourceManagePage: (context) => const SourceManagePage(),
    sourceFormPage: (context, { SourceModel? arguments }) => SourceFormPage(source: arguments,),
    settingPage: (context) => const SettingPage(),
    downloadPage: (context) => const DownloadPage(),
    localVideoPage: (context, { dynamic arguments }) => LocalVideoPage(
      localPath: arguments['localPath'] as String,
      name: arguments['name'] as String,
    ),
    collectionPage: (context) => const CollectionPage(),
    playRecordPage: (context) => const PlayRecordPage(),
    searchPage: (context, { dynamic arguments }) => SearchPage(
      hintText: arguments['hintText'] as String?,
      searchText: arguments['searchText'] as String?,
    ),
  };

  static Route<dynamic>? generateRoute (RouteSettings settings) {
    // 路由参数处理
    final Function? pageBuilder = routes[settings.name];
    if (pageBuilder != null) {
      if (settings.arguments != null) {
        return MaterialPageRoute<Widget>(
          settings: settings,
          builder: (context) => pageBuilder(context, arguments: settings.arguments) as Widget,
        );
      } else{
        return MaterialPageRoute<Widget>(
          settings: settings,
          builder: (context) => pageBuilder(context) as Widget,
        );
      }
    }
    return null;
  }
}
