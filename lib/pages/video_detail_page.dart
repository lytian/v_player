import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ijkplayer/flutter_ijkplayer.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/http_utils.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;
  final String name;

  VideoDetailPage({@required this.videoId, this.name});

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> with WidgetsBindingObserver {
  Future<VideoModel> _futureFetch;
  IjkMediaController _ijkMediaController = IjkMediaController();
  String _url;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _futureFetch = _getVideoInfo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:// 应用程序可见，前台
//        _videoPlayerController?.play();
        break;
      case AppLifecycleState.inactive: // 处于这种状态的应用程序应该假设它们可能在任何时候暂停。
      case AppLifecycleState.paused: // 应用程序不可见，后台
      case AppLifecycleState.detached:
        _ijkMediaController?.pause();
        break;
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    _ijkMediaController?.dispose();
//    db.close();
    WidgetsBinding.instance.addObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
            Container(
            color: Colors.black,
            height: MediaQueryData.fromWindow(window).padding.top,
          ),
          Container(
            height: 240,
            child: IjkPlayer(
              mediaController: _ijkMediaController,
            ),
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

  Future<VideoModel> _getVideoInfo() async {

    VideoModel video  = await HttpUtils.getVideoById(widget.videoId);
    if (video != null) {
      if (video.anthologies.isNotEmpty) {
        _url = video.anthologies.first.url;
//        String videoName = video.name + ' ' + video.anthologies.first.name;
        try {
          await _ijkMediaController.setNetworkDataSource(_url, autoPlay: false);
        } catch (e) {
          print(e);
        }
      }
    }
    return video;
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
                    child: Icon(Icons.file_download, color: Colors.grey, size: 24,),
                    onPressed: () {},
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
                  onPressed: () {
                    setState(() {
                      if (_url == e.url) return;
                      _url = e.url;
//                      _startVideoPlayer(video.name + ' ' + e.name);
                      _ijkMediaController.setNetworkDataSource(_url);
                    });
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
            child: Text(video.des ?? '', style: TextStyle(
              height: 1.8,
              fontSize: 14,
              color: Colors.black
            ),),
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

