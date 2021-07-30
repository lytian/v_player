import 'dart:async';
import 'dart:core';
import 'dart:ui';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:v_player/models/record_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:provider/provider.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:v_player/widgets/fijk_panel/fijk_panel.dart';

class VideoDetailPage extends StatefulWidget {
  final String videoId;

  VideoDetailPage({required this.videoId});

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late Future<VideoModel?> _futureFetch;
  DBHelper _db = DBHelper();
  final FijkPlayer _fijkPlayer = FijkPlayer();

  String? _url;
  String? _title;

  VideoModel? _videoModel;
  RecordModel? _recordModel;
  bool _isSingleVideo = false; // 是否单视频，没有选集
  int _cachePlayedSecond = -1; // 临时的播放秒数
  StreamSubscription? _currentPosSubs;

  @override
  void initState() {
    super.initState();
    _futureFetch = _getVideoInfo();
  }

  Future<VideoModel?>  _getVideoInfo() async {
    SourceModel? sourceModel = context.read<SourceProvider>().currentSource;
    VideoModel? video = await HttpUtils.getVideoById(sourceModel!.httpApi!, widget.videoId);
    _videoModel = video;
    if (video != null) {
      if (video.anthologies != null && video.anthologies!.isNotEmpty) {
        // 先查看是否有播放记录，默认从上次开始播放
        RecordModel? recordModel = await _db.getRecordByVid(sourceModel.httpApi!, widget.videoId);
        setState(() {
          _recordModel = recordModel;
          // 单视频，只有一个anthology，并且name为null
          if (video.anthologies!.length == 1 && video.anthologies!.first.name == null) {
            _isSingleVideo = true;
          }
        });

        String url;
        String name;
        int? position;
        if (_recordModel == null) {
          // 默认播放第一个
          url = video.anthologies!.first.url!;
          name = video.anthologies!.first.name == null ? video.name! : (video.name! + '  ' + video.anthologies!.first.name!);
        } else {
          // 自动跳转到历史
          int index = video.anthologies!.indexWhere((e) => e.name == _recordModel!.anthologyName);
          if (index > -1) {
            Anthology anthology = video.anthologies![index];
            url = anthology.url!;
            name = anthology.name == null ? video.name! : (video.name! + '  ' + anthology.name!);
          } else {
            url = video.anthologies!.first.url!;
            name = video.anthologies!.first.name == null ? video.name! : (video.name! + '  ' + video.anthologies!.first.name!);
          }
          position = recordModel!.playedTime;
        }

        _startPlay(url, name, playPosition: position ?? 0);
      }
    }
    return video;
  }

  void _startPlay(String url, String name, {
    int playPosition = 0,
    bool reset = false,
  }) async {
    setState(() {
      _url = url;
      _title = name;
    });
    if (reset) {
      // 切换视频，重置_cachePlayedSecond
      _cachePlayedSecond = -1;
      await _fijkPlayer.stop();
      await _fijkPlayer.reset();
    } else {
      // 添加播放完成状态的监听器
      _fijkPlayer.addListener(_completedListener);
      // 播放位置变化监听
      _currentPosSubs = _fijkPlayer.onCurrentPosUpdate.listen((curPos) {
        // 视频播放同一秒内不执行操作
        int position = curPos.inSeconds;
        if (position == _cachePlayedSecond) return;
        _cachePlayedSecond = position;

        String? anthologyName;
        if (!_isSingleVideo) {
          int index = _videoModel!.anthologies!.indexWhere((e) => e.url == _url);
          if (index > -1) {
            anthologyName = _videoModel!.anthologies![index].name;
          }
        }

        // 播放记录
        if (_recordModel == null) {
          SourceModel? sourceModel = context.read<SourceProvider>().currentSource;
          _recordModel = RecordModel(
              api: sourceModel!.httpApi,
              vid: widget.videoId,
              tid: _videoModel!.tid,
              type: _videoModel!.type,
              name: _videoModel!.name,
              pic: _videoModel!.pic,
              collected: 0,
              anthologyName: anthologyName,
              progress: 0,
              playedTime: 0
          );
          _db.insertRecord(_recordModel!).then((id) => _recordModel!.id = id);
        } else {
          _db.updateRecord(_recordModel!.id!,
              anthologyName: anthologyName,
              playedTime: position,
              progress: position / _fijkPlayer.value.duration.inSeconds
          );
        }
      });
    }

    // 设置视频源，并自动播放
    await _fijkPlayer.setDataSource(url, autoPlay: true);
    // Future.delayed(Duration(seconds: 10), () {
    //   _fijkPlayer.seekTo(playPosition * 1000);
    // });
  }

  @override
  void dispose() {
    _db.close();
    _fijkPlayer.removeListener(_completedListener);
    _currentPosSubs?.cancel();
    _fijkPlayer.release();

    super.dispose();
  }

  void _completedListener() async {
    // 播放完成
    if (_fijkPlayer.state == FijkState.completed) {
      // 多个选集，自动播放下一个
      if (_videoModel!.anthologies != null && _videoModel!.anthologies!.length > 1) {
        int index = _videoModel!.anthologies!.indexWhere((e) => e.url == _url);
        if (index > -1 && index != (_videoModel!.anthologies!.length - 1)) {
          Anthology next = _videoModel!.anthologies![index + 1];
          _startPlay(next.url!, _videoModel!.name! + '  ' + next.name!, reset: true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top,
            color: Colors.black,
          ),
          FijkView(
            height: MediaQuery.of(context).size.width / (16 / 9),
            color: Colors.black,
            player: _fijkPlayer,
            panelBuilder: (
                FijkPlayer player,
                FijkData data,
                BuildContext context,
                Size viewSize,
                Rect texturePos,
                ) {
              /// 使用自定义的布局
              return FijkPanel(
                player: player,
                pageContext: context,
                viewSize: viewSize,
                texturePos: texturePos,
                playerTitle: _title ?? '',
                actionWidget: _buildDownload(),
                playlistBuilder: (context, onClose) {
                  return _buildVideoPlaylist(onClose);
                },
                onReplay: () {
                  if (_url == null) return;

                  _startPlay(_url!, _title!, reset: true);
                },
              );
            },
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
                      return _buildScrollContent(snapshot.data as VideoModel);
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
        ],
      )
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
    if (video.year != null && video.year!.isNotEmpty) {
      arr.add(video.year);
    }
    if (video.area != null && video.area!.isNotEmpty) {
      arr.add(video.area);
    }
    if (video.lang != null && video.lang!.isNotEmpty) {
      arr.add(video.lang);
    }
    if (video.type != null && video.type!.isNotEmpty) {
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
                    Text(video.name ?? '', style: TextStyle(
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
                  if (_videoModel == null) return;
                  if (_recordModel == null) {
                    BotToast.showText(text: '请等待视频加载完成');
                    return;
                  }
                  int newCollected = _recordModel!.collected == 1 ? 0 : 1;
                  await _db.updateRecord(_recordModel!.id!, collected: newCollected);
                  setState(() {
                    _recordModel!.collected = newCollected;
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
            children: video.anthologies!.map((e) {
              return SizedBox(
                height: 36,
                child: ElevatedButton(
                  style: ButtonStyle(
                      elevation: MaterialStateProperty.all(0),
                      padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 8)),
                      backgroundColor: MaterialStateProperty.all(_url != e.url ? Colors.grey[300] : null)
                  ),
                  child: Text(e.name ?? '', style: TextStyle(
                      color: _url != e.url ? Colors.black : null,
                      fontSize: 14,
                      fontWeight: FontWeight.normal
                  ),),
                  onPressed: () async {
                    if (_url == e.url) return;

                    _startPlay(e.url!, video.name! + '  ' + e.name!, reset: true);
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

  Widget _buildLabelText(String label, String? text) {
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

  GestureDetector _buildDownload() {
    return GestureDetector(
      onTap: () async {
        if (_url == null || _url!.isEmpty
          || _title == null || _title!.isEmpty) {
          BotToast.showText(text: '视频未加载');
          return;
        }
        var provider = context.read<DownloadTaskProvider>();
        if (!await provider.checkStoragePermission()) {
          BotToast.showText(text: '没有存储权限');
          return;
        }
        await provider.createDownload(
          context: context,
          video: _videoModel!,
          url: _url!,
          name: _title!,
        );
        BotToast.showText(text: '开始下载【$_title】');
      },
      child: Container(
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 8.0),
        padding: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: Icon(
          Icons.file_download,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildVideoPlaylist(Function onClose) {
    if (_videoModel == null || _isSingleVideo) {
      return Container();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(15, 0, 15, 10),
      child: Wrap(
          spacing: 15,
          children: _videoModel!.anthologies!.map((anthology) {
            return ElevatedButton(
              style: ButtonStyle(
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                      side: BorderSide(color: _url == anthology.url ? Theme.of(context).primaryColor : Colors.white54)
                  ),
                ),
                elevation: MaterialStateProperty.all(0),
                backgroundColor: MaterialStateProperty.all(
                    _url == anthology.url ? Theme.of(context).primaryColor : Colors.black12
                ),
              ),
              onPressed: () {
                onClose.call();
                _startPlay(anthology.url!, _videoModel!.name! + '  ' + anthology.name!, reset: true);
              },
              child: Text(
                anthology.name ?? '',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            );
          }).toList()
      ),
    );
  }
}

