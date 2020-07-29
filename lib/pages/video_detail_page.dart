import 'dart:ui';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:video_player/video_player.dart';

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
        String name = video.name + '  ' + video.anthologies.first.name;
        _startPlay(url, name);
      }
    }
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

  void _initController(String url, String name) {
    // 设置资源
    _controller = VideoPlayerController.network(url);
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: 16 / 9,
      autoPlay: true,
      title: name,
      showControlsOnInitialize: false,
      allowedScreenSleep: false,
      onDownload: () {
        print(1111111111);
      }
    );
    setState(() {});
  }



  @override
  void dispose() {
//    db.close();
    _controller?.dispose();
    _chewieController?.dispose();

    super.dispose();
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
    if (video.year != null) {
      arr.add(video.year);
    }
    if (video.area != null) {
      arr.add(video.area);
    }
    if (video.lang != null) {
      arr.add(video.lang);
    }
    if (video.type != null) {
      arr.add(video.type);
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
//            Text(video.des ?? '', style: TextStyle(
//              height: 1.8,
//              fontSize: 14,
//              color: Colors.black
//            ),),
          ),
          SizedBox(
            height: 20,
          )
        ],
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

