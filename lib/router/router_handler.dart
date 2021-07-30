import 'package:fluro/fluro.dart';
import 'package:v_player/pages/collection_page.dart';
import 'package:v_player/pages/download_page.dart';
import 'package:v_player/pages/main_page.dart';
import 'package:v_player/pages/play_record_page.dart';
import 'package:v_player/pages/setting_page.dart';
import 'package:v_player/pages/source_manage_page.dart';
import 'package:v_player/pages/video_detail_page.dart';
import 'package:v_player/utils/fluro_convert_util.dart';

Handler mainHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
  return MainPage();
});

Handler detailHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
  String? videoId = params['id']?.first;
  return VideoDetailPage(videoId: videoId!);
});

Handler sourceManageHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
  return SourceManagePage();
});

Handler settingHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
  return SettingPage();
});

Handler downloadHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
      return DownloadPage();
    });

Handler collectionHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
      return CollectionPage();
    });

Handler playRecordHandle = Handler(
    handlerFunc: (context, Map<String, List<String>> params) {
      return PlayRecordPage();
    });