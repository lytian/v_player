import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.network(widget.url);
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      title: widget.name,
      autoPlay: true,
      showControlsOnInitialize: false,
      allowedScreenSleep: false,
      fullScreenByDefault: true,
      showDownload: false,
      allowFullScreen: false,
      onBack: () {
        // 退出全屏
        _chewieController.exitFullScreen();
        // 关闭页面
        Future.delayed(Duration(milliseconds: 400), () {
          Navigator.of(context).pop();
          Future.delayed(Duration(milliseconds: 100), () {
            Navigator.of(context).pop();
          });
        });
      }
    );
  }

  @override
  void dispose() {
    super.dispose();

    _controller.dispose();
    _chewieController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
      ),
      body: Chewie(
        controller: _chewieController,
      ),
    );
  }

  Widget _buildLoading() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topLeft,
            child: BackButton(color: Colors.white,),
          ),
          Center(
            child: CircularProgressIndicator(),
          )
        ],
      ),
    );
  }
}
