import 'package:auto_orientation/auto_orientation.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v_player/widgets/video_controls.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPage extends StatefulWidget {
  LocalVideoPage({this.url, this.name});

  final String url;
  final String name;

  @override
  _LocalVideoPageState createState() => _LocalVideoPageState();
}

class _LocalVideoPageState extends State<LocalVideoPage> {

  VideoPlayerController _controller;
  ChewieController _chewieController;
  double aspectRatio = 1;

  @override
  void initState() {
    super.initState();

    _initAsync();
  }

  void _initAsync() async {
    _controller = VideoPlayerController.network(widget.url);
    try {
      await _controller.initialize();
      // 根据长宽比，判断横屏还是竖屏
      if (_controller.value.aspectRatio <= 1) {
        AutoOrientation.portraitAutoMode();
      } else {
        AutoOrientation.landscapeAutoMode();
      }
    } catch(err) {
      print(err);
    }
    _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        allowedScreenSleep: false,
        allowFullScreen: false,
        fullScreenByDefault: false,
        playbackSpeeds: [0.5, 1, 1.25, 1.5, 2],
        customControls: VideoControls(
          title: widget.name,
          defaultShowTitle: true,
        )
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();

    // 销毁时，返回竖屏
    AutoOrientation.portraitAutoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _chewieController != null ? Chewie(
          controller: _chewieController,
        ) : Center(
          child: CircularProgressIndicator(),
        )
    );
  }
}