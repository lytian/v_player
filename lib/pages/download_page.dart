import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/models/download_model.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/widgets/no_data.dart';
import 'package:video_player/video_player.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isEdit = false;
  int _tabIndex = 0;

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    disposeVideo();
    super.dispose();
  }

  void disposeVideo() {
    _controller?.dispose();
    _chewieController?.removeListener(_fullscreenListener);
    _chewieController?.dispose();

    // _controller = null;
    // _chewieController = null;
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
        title: const Text("下载列表"),
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
          labelStyle: const TextStyle(
            fontSize: 16
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14
          ),
          tabs: const <Widget>[
            Tab(text: '已完成',),
            Tab(text: '缓存中',),
          ],
        )
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Expanded(
              child: Consumer<DownloadTaskProvider>(
                builder: (context, provider, _) {
                  final List<DownloadModel> successList = provider.downloadList.where((e) => e.status == DownloadStatus.success).toList();
                  final List<DownloadModel> downloadList = provider.downloadList.where((e) => e.status != DownloadStatus.success).toList();
                  if (successList.length != _checkSuccessList.length) {
                    _checkSuccessList = List.filled(successList.length, false);
                  }
                  if (downloadList.length != _checkDownloadList.length) {
                    _checkDownloadList = List.filled(downloadList.length, false);
                  }
                  return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildSuccessList(successList),
                        _buildDownloadList(downloadList, provider.currentTask),
                      ]
                  );
                },
              )
          ),
          if (_isEdit)
            Container(
              height: 44,
              decoration: const BoxDecoration(
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
                    margin: const EdgeInsets.only(left: 16),
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
                      onPressed: _deleteDownload,
                      child: const Text('删除'),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 68,
                    height: 32,
                    child: ElevatedButton(
                      style: ButtonStyle(
                          elevation: MaterialStateProperty.all(2),
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)
                          ))
                      ),
                      onPressed: _toggleAllChecked,
                      child: Text(isAllChecked ? '反选' : '全选'),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(),
        ],
      )
    );
  }

  Widget _buildSuccessList(List<DownloadModel> list) {
    if (list.isEmpty) {
      return const NoData(
        tip: '没有已完成下载的视频\n快去添加吧~',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final DownloadModel model = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: CachedNetworkImage(
              width: 96,
              height: 72,
              imageUrl: model.pic ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Image.asset('assets/image/placeholder-l.jpg', fit: BoxFit.cover,),
              errorWidget: (context, url, dynamic error) => Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage('assets/image/placeholder-l.jpg'),
                      fit: BoxFit.cover
                  ),
                ),
                alignment: Alignment.center,
                child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
              ),
            )
          ),
          title: Text(model.name ?? '暂无标题', style: const TextStyle(color: Colors.black, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 2,),
          subtitle: Text(model.type ?? '无', style: const TextStyle(fontSize: 13),),
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
              icon: const Icon(Icons.play_circle_outline),
              iconSize: 32,
              color: const Color(0xff3d3d3d),
              onPressed: ()  => _playVideo(model.savePath!, model.name!),
            ),
          onTap: () => _isEdit ? _toggleChecked(index) : _playVideo(model.savePath!, model.name!),
        );
      },
      separatorBuilder: (_, index) {
        return const Divider(color: Color(0xffd0d0d0),);
      },
      itemCount: list.length
    );
  }

  Widget _buildDownloadList(List<DownloadModel> list, DownloadTask? currentTask) {
    if (list.isEmpty) {
      return const NoData(
        tip: '没有缓存中的视频\n快去添加吧~',
      );
    }
    return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final DownloadModel model = list[index];
          String statusStr = '';
          switch (model.status) {
            case DownloadStatus.running:
              statusStr = '正在下载';
              break;
            case DownloadStatus.waiting:
              statusStr = '等待下载';
              break;
            case DownloadStatus.success:
              statusStr = '下载成功';
              break;
            case DownloadStatus.fail:
              statusStr = '下载失败';
              break;
            default:
              break;
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
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
            title: Text(model.name ?? '暂无标题', style: const TextStyle(color: Colors.black, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 2,),
            subtitle: currentTask != null && model.url == currentTask.url
                ? RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 13),
                    children: [
                      TextSpan(text: model.status == DownloadStatus.waiting ? '暂停中' : '正在下载', style: const TextStyle(color: Colors.grey)),
                      TextSpan(text: '    ${currentTask.formatSpeed == '' ? '加载中...' : currentTask.formatSpeed}', style: TextStyle(color: Theme.of(context).primaryColor))
                    ]
                  ),
                )
                : Text(statusStr, style: TextStyle(fontSize: 13, color: model.status == DownloadStatus.fail ? Colors.redAccent : null),),
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
                  backgroundColor: const Color(0xfff0f0f0),
                ),
                Icon(model.status == DownloadStatus.running ? Icons.pause : Icons.file_download, size: 20, color: Colors.grey,),
              ],
            ),
            onTap: () => _isEdit ? _toggleChecked(index) : _toggleDownload(model.url!),
          );
        },
        separatorBuilder: (_, index) {
          return const Divider(color: Color(0xffd0d0d0),);
        },
        itemCount: list.length
    );
  }

  void _fullscreenListener() {
    if (_chewieController != null && _chewieController!.isFullScreen) {
      // 退出全屏，关闭弹窗
      Navigator.pop(context);
    }
  }

  /// 播放视频
  Future<void> _playVideo(String localPath, String name) async {
    Navigator.of(context).pushNamed(Application.localVideoPage, arguments: {
      'localPath': localPath,
      'name': name,
    });
  }

  /// 切换单个选择
  void _toggleChecked(int index) {
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
        final bool isAllChecked = _checkSuccessList.every((e) => e);
        setState(() {
          if (isAllChecked) {
            _checkSuccessList = List.filled(_checkSuccessList.length, false);
          } else {
            _checkSuccessList = List.filled(_checkSuccessList.length, true);
          }
        });
      } else {
        if (_checkDownloadList.isEmpty) return;
        final bool isAllChecked = _checkDownloadList.every((e) => e);
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
    final List<DownloadModel> models = [];
    final List<DownloadModel> list = context.read<DownloadTaskProvider>().downloadList;
    if (_tabIndex == 0) {
      final List<DownloadModel> successList = list.where((e) => e.status == DownloadStatus.success).toList();
      for (int i = 0; i < _checkSuccessList.length; i++) {
        if (_checkSuccessList[i]) {
          models.add(successList[i]);
        }
      }
    } else {
      final List<DownloadModel> downloadList = list.where((e) => e.status != DownloadStatus.success).toList();
      for (int i = 0; i < _checkDownloadList.length; i++) {
        if (_checkDownloadList[i]) {
          models.add(downloadList[i]);
        }
      }
    }
    if (models.isEmpty) {
      BotToast.showText(text: '请选择待删除的视频');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('温馨提示'),
          content: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                const TextSpan(text: '确定删除 '),
                TextSpan(text: models.length == 1 ? models[0].name : '这${models.length}个视频', style: const TextStyle(color: Colors.orange)),
                const TextSpan(text: ' 吗？'),
              ]
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('取消', style: TextStyle(color: Colors.grey),),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('确定'),
              onPressed: () async {
                await context.read<DownloadTaskProvider>().deleteDownloads(models);
                setState(() {
                  _isEdit = false;
                });
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            )
          ],
        );
      }
    );
  }
}
