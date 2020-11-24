import 'package:auto_orientation/auto_orientation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v_player/widgets/chewie/chewie_player.dart';
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

  bool _initialized = false;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(widget.url);
    _controller.initialize().then((value) {
      // 根据长宽比，判断横屏还是竖屏
      if (_controller.value.aspectRatio < 1) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        AutoOrientation.landscapeAutoMode();
      }
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio: MediaQuery.of(context).size.width / MediaQuery.of(context).size.height,
        title: widget.name,
        looping: false,
        autoPlay: true,
        defaultShowTitle: true,
        allowFullScreen: false,
        showDownload: false,
        allowedScreenSleep: false
      );
      setState(() {
        _initialized = true;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _chewieController?.dispose();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _initialized ? Chewie(
          controller: _chewieController,
        ) : Center(
          child: CircularProgressIndicator(),
        )
    );
  }
}

class VideoScaffold extends StatefulWidget {
  const VideoScaffold({Key key, this.child, this.aspectRatio}) : super(key: key);

  final Widget child;
  final double aspectRatio;

  @override
  State<StatefulWidget> createState() => _VideoScaffoldState();
}

class _VideoScaffoldState extends State<VideoScaffold> {
  @override
  void initState() {
    // 根据长宽比，判断横屏还是竖屏
    if (widget.aspectRatio < 1) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      AutoOrientation.portraitAutoMode();
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
      AutoOrientation.landscapeAutoMode();
    }
    super.initState();
  }

  @override
  dispose() {
    // 销毁时，返回全屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AutoOrientation.portraitAutoMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
