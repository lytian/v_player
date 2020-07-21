import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadTaskProvider with ChangeNotifier {
//  DBHelper _db = DBHelper();
//  ReceivePort _port = ReceivePort();
//
//  List<VideoModel> _downloadVideoList = [];
//  DownloadTask _currentTask;
//
//  List<VideoModel> get downloadVideoList => _downloadVideoList;
//  DownloadTask get currentTask => _currentTask;
//
//  void init() async {
//    WidgetsFlutterBinding.ensureInitialized();
//    await M3u8Downloader.initialize();
//    M3u8Downloader.config(debugMode: false, saveDir: await findSavePath());
//    await Future.delayed(Duration(milliseconds: 500));
//
//    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
//    _port.listen((dynamic data) {
//      int status = data["status"];
//      switch (status) {
//        case 1:
//          _currentTask.state = data['state'];
//          _currentTask.speed = data['speed'];
//          _currentTask.formatSpeed = data['formatSpeed'];
//          _currentTask.progress = data["progress"];
//          _db.updateByOid(_currentTask.video.oid, progress: _currentTask.progress);
//          break;
//        case 2:
//          BotToast.showText(text:"【${_currentTask.video.name}】下载成功！！！");
//          _currentTask.progress = 1;
//          _currentTask.video.status = 2;
//          _db.updateByOid(_currentTask.video.oid, status: 2);
//          _currentTask = null;
//          // 下载下一个
//          //      if (_waitList.isNotEmpty) {
//          //      _currentVideo = _waitList.first;
//          //      _waitList.remove(_currentVideo);
//          //      _startDownload();
//          //      }
//          break;
//        case 3:
//          BotToast.showText(text:"【${_currentTask.video.name}】下载失败！！！");
//          _db.updateByOid(_currentTask.video.oid, status: 3);
//          _currentTask.video.status = 3;
//          _currentTask = null;
//          break;
//      }
//      notifyListeners();
//    });
//
//    _downloadVideoList = await _db.getVideoList();
//    notifyListeners();
//  }
//
//  Future<bool> startDownload(BuildContext context, { VideoModel video }) async {
//    bool hasGranted = await checkPermission();
//    if (!hasGranted) return false;
//    VideoModel newDownload;
//    if (video == null) {
//      // 在下载列表中查找新的下载
//      newDownload = _downloadVideoList.firstWhere((o) => o.status == 1);
//      // 没有正在下载的，下载等待状态的
//      if (newDownload == null) {
//        newDownload =  _downloadVideoList.firstWhere((o) => o.status == 0);
//      }
//    } else {
//      VideoModel temp = await _db.getVideoByUrl(video.url);
//      if (temp == null) {
//        // 创建新的下载任务
//        video.status = 0;
//        video.progress = 0.0;
//        int saveStatus = await _db.saveVideo(video);
//        if (saveStatus == 0) {
//          return false;
//        }
//      }
//    }
//
//    if (_currentTask == null) {
//      // 暂无正在下载
//
//    }
//    if (_currentTask != null && _currentTask.video.status == 1) return false;
//
//    if (video?.oid == _currentTask?.video?.oid)
//
//    notifyListeners();
//  }

  Future<String> findSavePath() async {
    final directory = Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory();
    String saveDir = directory.path + '/vPlayDownload';
    Directory root = Directory(saveDir);
    if (!root.existsSync()) {
      await root.create();
    }
    return saveDir;
  }

  Future<bool> checkPermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }
}

class DownloadTask {
  String url;
  double progress;
  int speed;
  String formatSpeed;
  String totalSize;
  int state;

  DownloadTask({
    @required this.url,
    this.progress,
    this.speed,
    this.formatSpeed,
    this.totalSize,
    this.state});
}