import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/download_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/permission_util.dart';
import 'package:v_player/utils/sp_helper.dart';

class DownloadTaskProvider with ChangeNotifier {
  DownloadTaskProvider(BuildContext context) {
    initialize(context);
  }

  final DBHelper _db = DBHelper();
  final ReceivePort _port = ReceivePort();
  StreamSubscription? _netSubscription;

  List<DownloadModel> _downloadList = [];
  DownloadTask? _currentTask;

  List<DownloadModel> get downloadList => _downloadList;
  DownloadTask? get currentTask => _currentTask;

  static void progressCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      args["status"] = 1;
      send.send(args);
    }
  }
  static void successCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      args['status'] = 2;
      send.send(args);
      BotToast.showText(text: '下载成功', align: Alignment.center);
    }
  }
  static void errorCallback(dynamic args) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    if (send != null) {
      args['status'] = 3;
      send.send(args);
      BotToast.showText(text: '下载失败', align: Alignment.center);
    }
  }

  ///
  /// 初始化
  ///
  Future<void> initialize(BuildContext context) async {
    // 1. 初始化下载器
    await M3u8Downloader.initialize(
      onSelect: () {
        return Navigator.of(context).pushNamed(Application.downloadPage);
      },
    );
    await M3u8Downloader.config(
      saveDir: await findSavePath('video'),
      convertMp4: SpHelper.getBool(Constant.keyM3u8ToMp4) ?? false,
      threadCount: 4,
      debugMode: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // 2. 绑定监听
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) async {
      if (_currentTask == null) return;

      final int status = data["status"] as int;
      switch (status) {
        case 1:
          _currentTask!.speed = data['speed'] as int;
          _currentTask!.formatSpeed = data['formatSpeed'] as String;
          _currentTask!.progress = data["progress"] / 1.0 as double;
          _currentTask!.totalSize = data["totalSize"] as int;
          _currentTask!.totalFormatSize = data["totalFormatSize"] as String;
          _currentTask!.currentFormatSize = data["currentFormatSize"] as String;
          _db.updateDownloadByUrl(_currentTask!.url, progress: _currentTask!.progress);
          break;
        case 2:
          BotToast.showText(text:"【${_currentTask!.name}】下载成功!!!");
          _currentTask!.progress = 1;
          _db.updateDownloadByUrl(_currentTask!.url, status: DownloadStatus.success, savePath: data['filePath'] as String);
          _downloadList = await _db.getDownloadList();
          _currentTask = null;
          // 下载下一个
          _downloadNext();
          break;
        case 3:
          BotToast.showText(text:"【${_currentTask!.name}】下载失败！！！");
          _db.updateDownloadByUrl(_currentTask!.url, status: DownloadStatus.fail);
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
      } else if (res == ConnectivityResult.mobile) {
        // 没有网络的处理
      } else if (res == ConnectivityResult.wifi) {
        // wifi自动下载
        if (currentTask == null && SpHelper.getBool(Constant.keyWifiAutoDownload, defValue: true) == true) {
          _downloadNext();
        }
      }
    });

    // 5. 自动下载
    if (SpHelper.getBool(Constant.keyWifiAutoDownload, defValue: true) == true) {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.wifi) {
        _downloadNext();
      }
    }

    notifyListeners();
  }

  ///
  /// 创建新的下载
  ///
  Future<void> createDownload({
    required VideoModel video,
    required String url,
    required String name,
    required BuildContext context,
  }) async {
    final String? httpApi = context.read<SourceProvider>().currentSource?.httpApi;
    // 1. 暂停正在下载
    final int index = _downloadList.indexWhere((e) => e.status == DownloadStatus.running);
    if (index > -1) {
      await pause(_downloadList[index].url!);
    }

    // 2. 查询是否拥有这个url的下载记录
    final DownloadModel? model = await _db.getDownloadByUrl(url);
    if (model != null) {
      // 3.2 下载当前
      await _db.updateDownloadByUrl(model.url!, status: DownloadStatus.running);
      _downloadList = await _db.getDownloadList();
      _downloadNext();
      return;
    }

    // 3.1 创建新的下载 TODO 与收藏的冲突处理。 api字段暂未处理
    final dynamic savePath = await M3u8Downloader.getSavePath(url);
    final String m3u8Path = savePath['m3u8'] as String;
    String fileId = '';
    if (m3u8Path.contains(path.separator)) {
      fileId = m3u8Path.split(path.separator)[m3u8Path.split(path.separator).length - 2];
    }
    await _db.insertDownload(DownloadModel(
      vid: video.id,
      tid: video.tid,
      name: name,
      url: url,
      api: httpApi,
      type: video.type,
      pic: video.pic,
      fileId: fileId,
      status: DownloadStatus.running,
      progress: 0,
      savePath: m3u8Path,
    ),);

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
    M3u8Downloader.pause(url);
    await _db.updateDownloadByUrl(url, status: DownloadStatus.waiting);
  }

  ///
  /// 切换下载
  ///
  Future<void> toggleDownload(String url) async {
    // 1. 查询是否拥有这个url的下载记录
    DownloadModel? self;
    final int index = _downloadList.indexWhere((e) => e.url == url);
    if (index == -1) {
      BotToast.showText(text: '下载任务不存在！', align: Alignment.center);
      return;
    }
    self = _downloadList[index];
    // 2. 切换自己的状态
    switch (self.status) {
      case DownloadStatus.running:
        // 正在下载状态
        // 2.1 先暂停自己的下载
        await pause(url);
        // 2.2 下一个下载
//        await _downloadNext();
        _downloadList = await _db.getDownloadList();
        // 2.3 刷新
        notifyListeners();
        break;
      case DownloadStatus.waiting:
      case DownloadStatus.fail:
        // 等待下载、下载失败状态
        // 2.1 暂停正在下载
        final int runningIndex = _downloadList.indexWhere((e) => e.status == DownloadStatus.running);
        if (runningIndex > -1) {
          await pause(_downloadList[runningIndex].url!);
        }
        // 2.2 开启本次下载，并刷新
        _startDownload(self.url!, self.name!);
        break;
      default:
        break;
    }
  }

  ///
  /// 删除下载列表
  ///
  Future<void> deleteDownloads(List<DownloadModel> models) async {
    if (models.isEmpty) return;
    // 1. 如果有正在 下载，先暂停
    final int runningIndex = _downloadList.indexWhere((e) => e.status == DownloadStatus.running);
    if (runningIndex > -1) {
      await pause(_downloadList[runningIndex].url!);
    }
    // 2. 删除本地文件
    for (final DownloadModel e in models) {
      M3u8Downloader.delete(e.url!);
    }
    // 3. 删除下载记录
    final int count = await _db.deleteDownloadByIds(models.map((e) => e.id!).toList());
    if (count <= 0) {
      BotToast.showText(text: '删除失败！');
      return;
    }
    // 4. 更新下载列表
    _downloadList = await _db.getDownloadList();
    // 5. 开启新的下载
    if (runningIndex > -1) {
      _downloadNext();
    }
    notifyListeners();
  }

  ///
  /// 下载下一个视频
  ///
  Future<void> _downloadNext() async {
    // 先寻找正在下载的视频
    final int runningIndex = _downloadList.indexWhere((e) => e.status == DownloadStatus.running);
    if (runningIndex > -1) {
      final DownloadModel runningDownload = _downloadList[runningIndex];
      await _startDownload(runningDownload.url!, runningDownload.name!);
      return;
    }
    // 寻找等待下载的视频
    final int wartIndex = _downloadList.indexWhere((e) => e.status == DownloadStatus.waiting);
    if (wartIndex > -1) {
      final DownloadModel waitDownload = _downloadList[wartIndex];
      await _startDownload(waitDownload.url!, waitDownload.name!);
      return;
    }
  }

  ///
  /// 开启下载
  ///
  Future<void> _startDownload(String url, String name) async {
    _currentTask = DownloadTask(name: name, url: url);
    await _db.updateDownloadByUrl(url, status: DownloadStatus.running);
    M3u8Downloader.download(
        url: url,
        name: name,
        progressCallback: progressCallback,
        successCallback: successCallback,
        errorCallback: errorCallback
    );
    _downloadList = await _db.getDownloadList();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _netSubscription?.cancel();
    _db.close();
  }
}

class DownloadTask {
  DownloadTask({
    required this.name,
    required this.url,
    this.progress = 0,
    this.speed = 0,
    this.formatSpeed = '',
    this.totalSize = 0,
    this.currentFormatSize = '',
    this.totalFormatSize = '',
  });

  String name;
  String url;
  double progress;
  int speed;
  int totalSize;
  String formatSpeed;
  String totalFormatSize;
  String currentFormatSize;
}
