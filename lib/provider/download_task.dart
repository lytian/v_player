import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:path/path.dart' as path;

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/widgets.dart';
import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/download_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/router/application.dart';
import 'package:v_player/router/routers.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:connectivity/connectivity.dart';
import 'package:v_player/utils/sp_helper.dart';

class DownloadTaskProvider with ChangeNotifier {

  DBHelper _db = DBHelper();
  ReceivePort _port = ReceivePort();
  StreamSubscription _netSubscription;

  List<DownloadModel> _downloadList = [];
  DownloadTask _currentTask;

  List<DownloadModel> get downloadList => _downloadList;
  DownloadTask get currentTask => _currentTask;

  static progressCallback(dynamic args) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    args["status"] = 1;
    send.send(args);
  }
  static successCallback(dynamic args) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send({"status": 2, "url": args["url"]});
    BotToast.showText(text: '下载成功', align: Alignment.center);
  }
  static errorCallback(dynamic args) {
    final SendPort send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send.send({"status": 3, "url": args["url"]});
    BotToast.showText(text: '下载失败', align: Alignment.center);
  }

  ///
  /// 初始化
  ///
  void initialize(BuildContext context) async {
    // 1. 初始化下载器
    WidgetsFlutterBinding.ensureInitialized();
    M3u8Downloader.initialize(
        saveDir: await findSavePath(),
        showNotification: true,
        debugMode: false,
        onSelect: () {
          Application.router.navigateTo(context, Routers.downloadPage);
          return null;
        }
    );
    await Future.delayed(Duration(milliseconds: 500));

    // 2. 绑定监听
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      if (_currentTask == null) return;

      int status = data["status"];
      switch (status) {
        case 1:
          _currentTask.speed = data['speed'];
          _currentTask.formatSpeed = data['formatSpeed'];
          _currentTask.progress = data["progress"];
          _db.updateDownloadByUrl(_currentTask.url, progress: _currentTask.progress);
          break;
        case 2:
          BotToast.showText(text:"【${_currentTask.name}】下载成功！！！");
          _currentTask.progress = 1;
          _db.updateDownloadByUrl(_currentTask.url, status: DownloadStatus.SUCCESS);
          _downloadList = await _db.getDownloadList();
          _currentTask = null;
          // 下载下一个
          _downloadNext();
          break;
        case 3:
          BotToast.showText(text:"【${_currentTask.name}】下载失败！！！");
          _db.updateDownloadByUrl(_currentTask.url, status: DownloadStatus.FAIL);
          _downloadList = await _db.getDownloadList();
          _currentTask = null;
          // 下载下一个
          _downloadNext();
          break;
      }
      notifyListeners();
    });

    // 3. 获取下载列表
    _downloadList = await _db.getDownloadList();

    // 4. 添加网络监听器
    _netSubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult res) {
      if (res == ConnectivityResult.none) {
        // 没有网络的处理
        print('没有网络了......');
      } else if (res == ConnectivityResult.mobile) {
        // 没有网络的处理
        print('切换到移动网络了......');
      } else if (res == ConnectivityResult.wifi) {
        // 没有网络的处理
        print('切换到WiFi了......');
      }
    });

    // 5. 自动下载
    if (SpHelper.getBool(Constant.key_wifi_auto_download, defValue: true)) {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.wifi) {
        _downloadNext();
      }
    }

    notifyListeners();
  }

  ///
  /// 创建新的下载
  ///
  void createDownload({ VideoModel video, String url, String name }) async {
    // 1. 暂停正在下载
    DownloadModel runningDownload = _downloadList.firstWhere((e) => e.status == DownloadStatus.RUNNING, orElse: () => null);
    if (runningDownload != null) {
      await pause(runningDownload.url);
    }

    // 2. 查询是否拥有这个url的下载记录
    DownloadModel model = await _db.getDownloadByUrl(url);
    if (model != null) {
      // 3.2 下载当前
      await _db.updateDownloadByUrl(model.url, status: DownloadStatus.RUNNING);
      _downloadList = await _db.getDownloadList();
      _downloadNext();
      return;
    }

    // 3.1 创建新的下载 TODO 与收藏的冲突处理。 api字段暂未处理
    String m3u8Path = await M3u8Downloader.getM3U8Path(url);
    String fileId = '';
    if (m3u8Path != null && m3u8Path.indexOf(path.separator) > -1) {
      fileId = m3u8Path.split(path.separator)[m3u8Path.split(path.separator).length - 2];
    }
    await _db.insertDownload(DownloadModel(
      vid: video.id,
      tid: video.tid,
      name: name,
      url: url,
      api: '',
      type: video.type,
      pic: video.pic,
      fileId: fileId,
      status: DownloadStatus.RUNNING,
      progress: 0,
      collected: 0,
      savePath: m3u8Path
    ));

    // 4. 刷新下载列表
    _downloadList = await _db.getDownloadList();
    // 5. 开启下载
    _downloadNext();
    notifyListeners();
  }

  ///
  /// 暂停下载
  ///
  Future<void> pause(String url) async {
    M3u8Downloader.cancel(url);
    await _db.updateDownloadByUrl(url, status: DownloadStatus.WAITING);
  }

  ///
  /// 下载下一个视频
  ///
  Future<void> _downloadNext() async {
    // 先寻找正在下载的视频
    DownloadModel runningDownload = _downloadList.firstWhere((e) => e.status == DownloadStatus.RUNNING, orElse: () => null);
    if (runningDownload != null) {
      _startDownload(runningDownload.url, runningDownload.name);
      return;
    }
    // 寻找等待下载的视频
    DownloadModel waitDownload = _downloadList.firstWhere((e) => e.status == DownloadStatus.WAITING, orElse: () => null);
    if (waitDownload != null) {
      await pause(waitDownload.url);
      _startDownload(waitDownload.url, waitDownload.name);
      return;
    }
  }

  ///
  /// 开启下载
  ///
  void _startDownload(String url, String name) async {
    bool hasGranted = await checkStoragePermission();
    if (!hasGranted) return;
    _currentTask = DownloadTask(name: name, url: url);
    M3u8Downloader.download(
        url: url,
        name: name,
        progressCallback: progressCallback,
        successCallback: successCallback,
        errorCallback: errorCallback
    );
  }

  ///
  /// 获取文件存储路径。跟路径
  ///
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

  ///
  /// 检查存储权限
  ///
  Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  @override
  void dispose() {
    super.dispose();
    _netSubscription.cancel();
  }
}

class DownloadTask {
  String name;
  String url;
  double progress;
  int speed;
  String formatSpeed;
  String totalSize;

  DownloadTask({
    @required this.name,
    @required this.url,
    this.progress,
    this.speed,
    this.formatSpeed,
    this.totalSize});
}