import 'dart:io';

import 'package:auto_orientation/auto_orientation.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:v_player/widgets/video_controls/video_controls.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPage extends StatefulWidget {
  LocalVideoPage({required this.localPath, required this.name});

  final String localPath;
  final String name;

  @override
  _LocalVideoPageState createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {

  late VideoPlayerController _controller;
  ChewieController? _chewieController;
  bool _isLandscape = false;

  @override
  void initState() {
    super.initState();

    _initAsync();
  }

  void _initAsync() async {
    _controller = VideoPlayerController.file(File(widget.localPath));
    try {
      await _controller.initialize();
      // 隐藏状态栏
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
      // 判断是否需要自动旋转
      final videoWidth = _controller.value.size.width;
      final videoHeight = _controller.value.size.height;
      _isLandscape = videoWidth > videoHeight;
      if (_isLandscape) {
        AutoOrientation.landscapeAutoMode(forceSensor: true);
      }
    } catch(err) {
      print(err);
    }
    // 打开屏幕唤醒状态
    FlutterScreenWake.keepOn(true);
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      allowedScreenSleep: false,
      allowFullScreen: false,
      fullScreenByDefault: false,
      playbackSpeeds: [0.5, 1, 1.25, 1.5, 2],
      customControls: VideoControls(
        title: widget.name,
        alwaysShowTitle: true,
      )
    );
    setState(() {});
  }

  @override
  void dispose() {
    // 关闭屏幕唤醒状态
    FlutterScreenWake.keepOn(false);
    // 恢复状态栏的默认显示
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    // 竖屏
    AutoOrientation.portraitAutoMode();

    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _chewieController != null ? Chewie(
        controller: _chewieController!,
      ) : Center(
        child: CircularProgressIndicator(),
      )
    );
  }
}