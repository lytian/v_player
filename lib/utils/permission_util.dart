import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// 检查存储权限
Future<bool> checkStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
  status = await Permission.storage.request();
  }
  return status.isGranted;
}

/// 检查拍照权限
Future<bool> checkCameraPermission() async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    status = await Permission.camera.request();
  }
  return status.isGranted;
}

/// 检查定位权限
Future<bool> checkLocationPermission() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    status = await Permission.location.request();
  }
  return status.isGranted;
}

/// 获取文件存储路径
Future<String> findSavePath([ String? basePath ]) async {
  final directory = Platform.isAndroid
      ? await getExternalStorageDirectory()
      : await getApplicationDocumentsDirectory();
  if (basePath == null) {
    return directory!.path;
  }
  final String saveDir = path.join(directory!.path, basePath);
  final Directory root = Directory(saveDir);
  if (!root.existsSync()) {
    await root.create();
  }
  return saveDir;
}
