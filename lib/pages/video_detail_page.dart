import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:v_player/widgets/chewie/chewie_player.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;

  VideoDetailPage(this.videoId);

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  Future<VideoModel> _futureFetch;
  VideoPlayerController _controller;
  ChewieController _chewieController;
  String _url;
  VideoModel _videoModel;
  bool _isSingleVideo = false; // 是否单视频，没有选集

  @override
  void initState() {
    super.initState();
    _futureFetch = _getVideoInfo();
  }

  Future<VideoModel> _getVideoInfo() async {
    VideoModel video  = await HttpUtils.getVideoById(widget.videoId);
    if (video != null) {
      if (video.anthologies.isNotEmpty) {
        String url = video.anthologies.first.url;
        String name = video.anthologies.first.name == null ? video.name : (video.name + '  ' + video.anthologies.first.name);
        // 单视频，只有一个anthology，并且name为null
        if (video.anthologies.length == 1 && video.anthologies.first.name == null) {
          setState(() {
            _isSingleVideo = true;
          });
        }
        _startPlay(url, name);
      }
    }
    _videoModel = video;
    return video;
  }

  void _startPlay(String url, String name) async {
    setState(() {
      _url = url;
    });
    if (_controller == null) {
      _initController(url, name);
      return;
    }
    // 备份旧的controller
    final oldController = _controller;
    // 在下一帧处理完成后
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      oldController.removeListener(_videoListener);
      // 注销旧的controller;
      await oldController.dispose();
      _chewieController?.dispose();
      // 初始化一个新的controller
      _initController(url, name);
    });
    // 刷新状态
    setState(() {
      _controller = null;
    });
  }

  void _initController(String url, String name) async {
    // 设置资源
    _controller = VideoPlayerController.network(url);
    _controller.addListener(_videoListener);

    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: 16 / 9,
      autoPlay: true,
      title: name,
      showControlsOnInitialize: false,
      allowedScreenSleep: false,
      onDownload: () async {
        await context.read<DownloadTaskProvider>().createDownload(
          context: context,
          video: _videoModel,
          url: url,
          name: name
        );
        BotToast.showText(text: '开始下载【$name】');
      }
    );
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _chewieController?.dispose();

    super.dispose();
  }

  void _videoListener() {
    // 多个视频时
    if (_videoModel != null && _videoModel.anthologies.isNotEmpty && _videoModel.anthologies.length > 1) {
      // 播放到最后，切换下一个视频
      if (_controller != null && _controller.value.isPlaying && _controller.value.position.compareTo(_controller.value.duration) >= 0) {
        int index = _videoModel.anthologies.indexWhere((e) => e.url == _url);
        if (index > -1 && index != (_videoModel.anthologies.length - 1)) {
          Anthology next = _videoModel.anthologies[index + 1];
          _startPlay(next.url, _videoModel.name + '  ' + next.name);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(top: MediaQueryData.fromWindow(window).padding.top),
            color: Colors.black,
            child: _controller == null
                ? _buildLoading()
                : Chewie(
                  controller: _chewieController,
                )
          ),
          Expanded(
            flex: 1,
            child: FutureBuilder(
              future: _futureFetch,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    return _buildText('网络请求出错了');
                  }
                  if (snapshot.hasData && snapshot.data != null) {
                    try {
                      return _buildScrollContent(snapshot.data);
                    } catch (e) {
                      print(e);
                      return Center(
                        child: Text('数据解析错误'),
                      );
                    }
                  } else {
                    return _buildText('没有找到视频');
                  }
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              }
            ),
          )
        ]
      )
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

  Widget _buildText(String str) {
    return Container(
      child: Center(
        child: Text(str, style: TextStyle(
          color: Colors.redAccent,
          fontSize: 16
        )),
      ),
    );
  }

  Widget _buildScrollContent(VideoModel video) {
    List arr = [];
    if (video.year != null && video.year.isNotEmpty) {
      arr.add(video.year);
    }
    if (video.area != null && video.area.isNotEmpty) {
      arr.add(video.area);
    }
    if (video.lang != null && video.lang.isNotEmpty) {
      arr.add(video.lang);
    }
    if (video.type != null && video.type.isNotEmpty) {
      arr.add(video.type);
    }

    List<Widget> children = [];
    // 添加视频标题和说明
    children.addAll([
      Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(video.name, style: TextStyle(
            color: Colors.black,
            fontSize: 18
        ),),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(arr.join('/'), style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
            height: 1
        ),),
      ),
      Padding(
        padding: EdgeInsets.only(top: 8, bottom: 4),
        child: Divider(
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
    ]);
    // 添加选集
    if (!_isSingleVideo) {
      children.addAll([
        Padding(
            padding: EdgeInsets.only(left: 16,),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Text('选集', style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      height: 1
                  )),
                ),
                Container(
                  height: 12,
                  child: VerticalDivider(color: Colors.grey,),
                ),
                Container(
                  width: 48,
                  height: 30,
                  margin: EdgeInsets.only(right: 6),
                  child: MaterialButton(
                    padding: EdgeInsets.all(0),
                    child: Icon(Icons.star_border, color: Colors.grey, size: 24,),
                    onPressed: () {
                      print('收藏视频');
                    },
                  ),
                ),
              ],
            )
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 0,
            children: video.anthologies.map((e) {
              return RaisedButton(
                elevation: 0,
                highlightElevation: 4,
                color: _url == e.url ? Theme.of(context).primaryColor : null,
                child: Text(e.name, style: TextStyle(
                    color: _url == e.url ? Colors.white : null,
                    fontSize: 14,
                    fontWeight: FontWeight.normal
                ),),
                onPressed: () async {
                  if (_url == e.url) return;

                  _startPlay(e.url, video.name + '  ' + e.name);
                },
              );
            }).toList(),
          ),
        ),
        Divider(
          color: Colors.grey.withOpacity(0.5),
        ),
      ]);
    }
    // 添加简介
    children.addAll([
      Padding(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text('简介', style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            height: 1
        )),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('地区', video.area),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('年份', video.year),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('分类', video.type),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('导演', video.director),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('演员', video.actor),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: _buildLabelText('发布', video.last),
      ),
      Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: HtmlWidget(
            video.des ?? '',
            textStyle: TextStyle(
                height: 1.8,
                fontSize: 14,
                color: Colors.black
            ),
          )
      ),
    ]);
    // 添加底部占位
    children.add(SizedBox(
      height: 20,
    ));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildLabelText(String label, String text) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: label, style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            letterSpacing: 4
          )),
          TextSpan(text: '：  ', style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          )),
          TextSpan(text: text ?? '', style: TextStyle(
            fontSize: 14,
            color: Colors.black,
            height: 1.6
          )),
        ]
      )
    );
  }
}

