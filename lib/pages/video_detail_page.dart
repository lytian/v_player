import 'dart:async';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/record_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:v_player/utils/sp_helper.dart';
import 'package:v_player/widgets/chewie/chewie_player.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

class VideoDetailPage extends StatefulWidget {
  final String api;
  final String videoId;

  VideoDetailPage({this.api, @required this.videoId});

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  Future<VideoModel> _futureFetch;
  VideoPlayerController _controller;
  ChewieController _chewieController;
  DBHelper _db = DBHelper();


  String _url;
  SourceModel _currentSource;
  VideoModel _videoModel;
  RecordModel _recordModel;
  bool _isSingleVideo = false; // 是否单视频，没有选集
  int _cachePlayedSecond = -1; // 临时的播放秒数

  @override
  void initState() {
    super.initState();
    _futureFetch = _getVideoInfo();
  }

  Future<VideoModel> _getVideoInfo() async {
    String baseUrl = widget.api;
    if (baseUrl == null) {
      Map<String, dynamic> sourceJson = SpHelper.getObject(Constant.key_current_source);
      _currentSource = SourceModel.fromJson(sourceJson);
      baseUrl = _currentSource.httpApi;
    }
    VideoModel video  = await HttpUtils.getVideoById(baseUrl, widget.videoId);
    _videoModel = video;
    if (video != null) {
      if (video.anthologies.isNotEmpty) {
        // 先查看是否有播放记录，默认从上次开始播放
        RecordModel recordModel = await _db.getRecordByVid(baseUrl, widget.videoId);
        setState(() {
          _recordModel = recordModel;

          // 单视频，只有一个anthology，并且name为null
          if (video.anthologies.length == 1 && video.anthologies.first.name == null) {
            _isSingleVideo = true;
          }
        });

        String url;
        String name;
        int position;
        if (_recordModel == null) {
          // 默认播放第一个
          url = video.anthologies.first.url;
          name = video.anthologies.first.name == null ? video.name : (video.name + '  ' + video.anthologies.first.name);
        } else {
          // 自动跳转到历史
          Anthology anthology = video.anthologies.firstWhere((e) => e.name == _recordModel.anthologyName, orElse: () => null);
          if (anthology != null) {
            url = anthology.url;
            name = anthology.name == null ? video.name : (video.name + '  ' + anthology.name);
          } else {
            url = video.anthologies.first.url;
            name = video.anthologies.first.name == null ? video.name : (video.name + '  ' + video.anthologies.first.name);
          }
          position = recordModel.playedTime;
        }

        _startPlay(url, name, playPosition: position);
      }
    }
    return video;
  }

  void _startPlay(String url, String name, { int playPosition }) async {
    // 切换视频，重置_cachePlayedSecond
    _cachePlayedSecond = -1;

    setState(() {
      _url = url;
    });
    if (_controller == null) {
      _initController(url, name, playPosition: playPosition);
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

  void _initController(String url, String name, { int playPosition }) async {
    // 设置资源
    _controller = VideoPlayerController.network(url, videoPlayerOptions: VideoPlayerOptions(
      mixWithOthers: true
    ));
    _controller.addListener(_videoListener);

    Duration position;
    if (playPosition != null) {
      position = Duration(milliseconds: playPosition);
    }
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: 16 / 9,
      autoPlay: true,
      autoPlayPosition: position,
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
    _db.close();

    super.dispose();
  }

  void _videoListener() async {
    if (_videoModel == null || _controller == null || !_controller.value.isPlaying) return;
    // 视频播放同一秒内不执行操作
    if (_controller.value.position.inSeconds == _cachePlayedSecond) return;
    _cachePlayedSecond = _controller.value.position.inSeconds;

    String anthologyName;
    if (!_isSingleVideo) {
      Anthology anthology = _videoModel.anthologies.firstWhere((e) => e.url == _url, orElse: () => null);
      if (anthology != null) {
        anthologyName = anthology.name;
      }
    }

    // 播放记录
    if (_recordModel == null) {
      _recordModel = RecordModel(
        api: _currentSource.httpApi,
        vid: widget.videoId,
        tid: _videoModel.tid,
        type: _videoModel.type,
        name: _videoModel.name,
        pic: _videoModel.pic,
        collected: 0,
        anthologyName: anthologyName,
        progress: 0,
        playedTime: 0
      );
      _recordModel.id = await _db.insertRecord(_recordModel);
    } else {
      _db.updateRecord(_recordModel.id,
          anthologyName: anthologyName,
          playedTime: _controller.value.position.inMilliseconds,
          progress: _controller.value.position.inMilliseconds / _controller.value.duration.inMilliseconds
      );
    }

    // 多个选集
    if (_videoModel.anthologies != null && _videoModel.anthologies.length > 1) {
      // 播放到最后，切换下一个视频
      if (_cachePlayedSecond >= _controller.value.duration.inSeconds) {
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
                    print(snapshot.error);
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.name, style: TextStyle(
                    color: Colors.black,
                    fontSize: 18
                  ),),
                  SizedBox(
                    height: 4,
                  ),
                  Text(arr.join('/'), style: TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                      height: 1
                  ),),
                ],
              )
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
                padding: EdgeInsets.zero,
                child: Icon(_recordModel?.collected == 1 ? Icons.star : Icons.star_border,
                  color: _recordModel?.collected == 1 ? Theme.of(context).primaryColor : Colors.grey,
                  size: 24,
                ),
                onPressed: () async {
                  if (_currentSource == null || _videoModel == null) return;

                  if (_recordModel == null) {
                    BotToast.showText(text: '请等待视频加载完成');
                    return;
                  }
                  int newCollected = _recordModel.collected == 1 ? 0 : 1;
                  await _db.updateRecord(_recordModel.id, collected: newCollected);
                  setState(() {
                    _recordModel.collected = newCollected;
                  });
                  BotToast.showText(text: newCollected == 1 ? '收藏成功' : '取消收藏成功');
                },
              ),
            ),
          ],
        )
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
            child: Text('选集', style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                height: 1
            )),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: video.anthologies.map((e) {
              return SizedBox(
                height: 36,
                child: RaisedButton(
                  elevation: 0,
                  highlightElevation: 4,
                  padding: EdgeInsets.symmetric(horizontal: 8),
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
                )
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

