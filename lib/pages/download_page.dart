import 'package:bot_toast/bot_toast.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/models/download_model.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/widgets/fijk_panel/fijk_panel.dart';
import 'package:v_player/widgets/no_data.dart';

class DownloadPage extends StatefulWidget {
  @override
  _DownloadPageState createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FijkPlayer _fijkPlayer = FijkPlayer();
  bool _isEdit = false;
  int _tabIndex = 0;
  bool _opened = false;

  List<bool> _checkSuccessList = [];
  List<bool> _checkDownloadList = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _tabIndex = _tabController.index;
      });
    });

    _fijkPlayer.setOption(FijkOption.hostCategory, "request-screen-on", 1);
    _fijkPlayer.addListener(_fullscreenListener);
  }

  @override
  void dispose() {
    _fijkPlayer.removeListener(_fullscreenListener);
    _fijkPlayer.release();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    bool isAllChecked = false;
    if (_isEdit) {
      if (_tabIndex == 0) {
        isAllChecked = _checkSuccessList.isNotEmpty && _checkSuccessList.every((e) => e);
      } else {
        isAllChecked = _checkDownloadList.isNotEmpty && _checkDownloadList.every((e) => e);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("下载列表"),
        actions: <Widget>[
          IconButton(
            tooltip: _isEdit ? '完成' : '管理',
            icon: Icon(_isEdit ? Icons.check : Icons.playlist_add_check),
            iconSize: 28,
            onPressed: () {
              setState(() {
                _isEdit = !_isEdit;
                if (_isEdit) {
                  _checkDownloadList = List.filled(_checkDownloadList.length, false);
                  _checkSuccessList = List.filled(_checkSuccessList.length, false);
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(
            fontSize: 16
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 14
          ),
          tabs: <Widget>[
            Tab(text: '已完成',),
            Tab(text: '缓存中',),
          ],
        )
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Consumer<DownloadTaskProvider>(
                builder: (context, provider, _) {
                  List<DownloadModel> _successList = provider.downloadList.where((e) => e.status == DownloadStatus.SUCCESS).toList();
                  List<DownloadModel> _downloadList = provider.downloadList.where((e) => e.status != DownloadStatus.SUCCESS).toList();
                  if (_successList.length != _checkSuccessList.length) {
                    _checkSuccessList = List.filled(_successList.length, false);
                  }
                  if (_downloadList.length != _checkDownloadList.length) {
                    _checkDownloadList = List.filled(_downloadList.length, false);
                  }
                  return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSuccessList(_successList),
                        _buildDownloadList(_downloadList, provider.currentTask),
                      ]
                  );
                },
              )
          ),
          _isEdit ? Container(
            height: 44,
            decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xffdedede),
                    blurRadius: 4, //阴影范围
                    spreadRadius: 1, //阴影浓度
                  )
                ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(left: 16),
                  width: 68,
                  height: 32,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Theme.of(context).primaryColor),
                        elevation: MaterialStateProperty.all(2),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)
                        ))
                    ),
                    child: Text('删除'),
                    onPressed: _deleteDownload,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 16),
                  width: 68,
                  height: 32,
                  child: ElevatedButton(
                    style: ButtonStyle(
                        elevation: MaterialStateProperty.all(2),
                        shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)
                        ))
                    ),
                    child: Text(isAllChecked ? '反选' : '全选'),
                    onPressed: _toggleAllChecked,
                  ),
                ),
              ],
            ),
          ) : Container(),
        ],
      )
    );
  }

  Widget _buildSuccessList(List<DownloadModel> list) {
    if (list.isEmpty) {
      return NoData(
        tip: '没有已完成下载的视频\n快去添加吧~',
      );
    }
    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemBuilder: (context, index) {
        DownloadModel model = list[index];
        return ListTile(
          contentPadding: EdgeInsets.all(0),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: FadeInImage.assetNetwork(
              placeholder: 'assets/image/placeholder-l.jpg',
              image: model.pic ?? '',
              fit: BoxFit.cover,
              width: 100,
              height: 75,
            ),
          ),
          title: Text(model.name ?? '暂无标题', style: TextStyle(color: Colors.black, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 2,),
          subtitle: Text(model.type ?? '无', style: TextStyle(fontSize: 13),),
          trailing: _isEdit
            ? Checkbox(
              value: _checkSuccessList[index],
              onChanged: (v) {
                setState(() {
                  _checkSuccessList[index] = v ?? false;
                });
              },
            )
            : IconButton(
              icon: Icon(Icons.play_circle_outline),
              iconSize: 32,
              color: Color(0xff3d3d3d),
              onPressed: ()  => _playVideo(model.savePath!, model.name!),
            ),
          onTap: () => _isEdit ? _toggleChecked(index) : _playVideo(model.savePath!, model.name!),
        );
      },
      separatorBuilder: (_, index) {
        return Divider(color: Color(0xffd0d0d0),);
      },
      itemCount: list.length
    );
  }

  Widget _buildDownloadList(List<DownloadModel> list, DownloadTask? currentTask) {
    if (list.isEmpty) {
      return NoData(
        tip: '没有缓存中的视频\n快去添加吧~',
      );
    }
    return ListView.separated(
        padding: EdgeInsets.all(16),
        itemBuilder: (context, index) {
          DownloadModel model = list[index];
          String statusStr = '';
          switch (model.status) {
            case DownloadStatus.RUNNING:
              statusStr = '正在下载';
              break;
            case DownloadStatus.WAITING:
              statusStr = '等待下载';
              break;
            case DownloadStatus.SUCCESS:
              statusStr = '下载成功';
              break;
            case DownloadStatus.FAIL:
              statusStr = '下载失败';
              break;
            default:
              break;
          }
          return ListTile(
            contentPadding: EdgeInsets.all(0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/image/placeholder-p.jpg',
                image: model.pic ?? '',
                fit: BoxFit.cover,
                width: 100,
                height: 75,
              ),
            ),
            title: Text(model.name ?? '暂无标题', style: TextStyle(color: Colors.black, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 2,),
            subtitle: currentTask != null && model.url == currentTask.url
                ? RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13),
                    children: [
                      model.status == DownloadStatus.WAITING
                      ? TextSpan(text: '暂停中', style: TextStyle(color: Colors.grey))
                      : TextSpan(text: '正在下载', style: TextStyle(color: Colors.grey)) ,
                      TextSpan(text: '    ' +  (currentTask.formatSpeed == '' ? '加载中...' : currentTask.formatSpeed), style: TextStyle(color: Theme.of(context).primaryColor))
                    ]
                  ),
                )
                : Text(statusStr, style: TextStyle(fontSize: 13, color: model.status == DownloadStatus.FAIL ? Colors.redAccent : null),),
            trailing: _isEdit
                ? Checkbox(
              value: _checkDownloadList[index],
              onChanged: (v) {
                setState(() {
                  _checkDownloadList[index] = v ?? false;
                });
              },
            )
            : Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: currentTask != null && model.url == currentTask.url ? currentTask.progress : model.progress,
                  strokeWidth: 3,
                  backgroundColor: Color(0xfff0f0f0),
                ),
                Icon(model.status == DownloadStatus.RUNNING ? Icons.pause : Icons.file_download, size: 20, color: Colors.grey,),
              ],
            ),
            onTap: () => _isEdit ? _toggleChecked(index) : _toggleDownload(model.url!),
          );
        },
        separatorBuilder: (_, index) {
          return Divider(color: Color(0xffd0d0d0),);
        },
        itemCount: list.length
    );
  }

  void _fullscreenListener() {
    if (_opened && !_fijkPlayer.value.fullScreen) {
      // 退出全屏，关闭弹窗
      Navigator.pop(context);
    }
  }

  /// 播放视频
  void _playVideo(String url, String name) async {
    await _fijkPlayer.setDataSource(url, autoPlay: true);
    _fijkPlayer.enterFullScreen();
    _opened = true;
    showDialog(
      context: context,
      builder: (BuildContext buildContext) {
        return Material(
          child: FijkView(
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
                playerTitle: name,
                allowFullScreen: false,
              );
            },
          ),
        );
      }
    ).then((res) async {
      _opened = false;
      await _fijkPlayer.stop();
      await _fijkPlayer.reset();
    });
  }

  /// 切换单个选择
  void _toggleChecked(index) {
    setState(() {
      if (_tabIndex == 0) {
        _checkSuccessList[index] = !_checkSuccessList[index];
      } else {
        _checkDownloadList[index] = !_checkDownloadList[index];
      }
    });
  }

  /// 切换全选
  void _toggleAllChecked() {
      if (_tabIndex == 0) {
        if (_checkSuccessList.isEmpty) return;
        bool isAllChecked = _checkSuccessList.every((e) => e);
        setState(() {
          if (isAllChecked) {
            _checkSuccessList = List.filled(_checkSuccessList.length, false);
          } else {
            _checkSuccessList = List.filled(_checkSuccessList.length, true);
          }
        });
      } else {
        if (_checkDownloadList.isEmpty) return;
        bool isAllChecked = _checkDownloadList.every((e) => e);
        setState(() {
          if (isAllChecked) {
            _checkDownloadList = List.filled(_checkDownloadList.length, false);
          } else {
            _checkDownloadList = List.filled(_checkDownloadList.length, true);
          }
        });
      }
  }

  /// 切换下载状态
  void _toggleDownload(String url) {
    context.read<DownloadTaskProvider>().toggleDownload(url);
  }

  /// 删除下载
  void _deleteDownload() {
    List<DownloadModel> _models = [];
    List<DownloadModel> downloadList = context.read<DownloadTaskProvider>().downloadList;
    if (_tabIndex == 0) {
      List<DownloadModel> _successList = downloadList.where((e) => e.status == DownloadStatus.SUCCESS).toList();
      for (int i = 0; i < _checkSuccessList.length; i++) {
        if (_checkSuccessList[i]) {
          _models.add(_successList[i]);
        }
      }
    } else {
      List<DownloadModel> _downloadList = downloadList.where((e) => e.status != DownloadStatus.SUCCESS).toList();
      for (int i = 0; i < _checkDownloadList.length; i++) {
        if (_checkDownloadList[i]) {
          _models.add(_downloadList[i]);
        }
      }
    }
    if (_models.isEmpty) {
      BotToast.showText(text: '请选择待删除的视频');
      return;
    }
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('温馨提示'),
          content: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black),
              children: [
                TextSpan(text: '确定删除 '),
                TextSpan(text: _models.length == 1 ? _models[0].name : '这${_models.length}个视频', style: TextStyle(color: Colors.orange)),
                TextSpan(text: ' 吗？'),
              ]
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('取消', style: TextStyle(color: Colors.grey),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                await context.read<DownloadTaskProvider>().deleteDownloads(_models);
                setState(() {
                  _isEdit = false;
                });
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }
}
