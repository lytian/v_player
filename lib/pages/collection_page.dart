import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:v_player/models/record_model.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/widgets/no_data.dart';

class CollectionPage extends StatefulWidget {
  const CollectionPage({Key? key}) : super(key: key);

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final DBHelper _db = DBHelper();
  final EasyRefreshController _controller = EasyRefreshController();

  int _pageNum = -1; // 从0开始
  List<RecordModel> _recordList = [];

  Future<void> _getRecordList() async {
    final List<RecordModel> list = await _db.getRecordList(pageNum: _pageNum, collected: 1);
    if (!mounted) return;
    setState(() {
      if (_pageNum <= 0) {
        _recordList = list;
      } else {
        _recordList += list;
      }
    });
    _controller.finishLoad(list.length < 20 ? IndicatorResult.noMore : IndicatorResult.success);
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
      ),
      body: EasyRefresh(
        controller: _controller,
        onRefresh: () async {
          _pageNum = 0;
          await _getRecordList();
        },
        onLoad: () async {
          _pageNum++;
          await _getRecordList();
        },
        child: _recordList.isEmpty
          ? const NoData(tip: '没有收藏记录',)
          : ListView.builder(
            itemCount: _recordList.length,
              itemBuilder: (context, index) {
                final RecordModel model = _recordList[index];
                String recordStr = '';
                if (model.progress != null && model.progress! > 0) {
                  if (model.anthologyName != null) {
                    recordStr += model.anthologyName!;
                  }
                  if (model.progress! > 0.99) {
                    recordStr += ' ' + '播放完毕';
                  } else {
                    recordStr = '播放至：$recordStr ${(model.progress! * 100).toStringAsFixed(2)}';
                  }
                }
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                  subtitle: recordStr.isEmpty ? RichText(
                    text: TextSpan(
                        style: const TextStyle(fontSize: 13, color: Color(0xff666666)),
                        children: [
                          TextSpan(text: model.type),
                          const TextSpan(text: '  暂无播放', style: TextStyle(color: Color(0xff999999)))
                        ]
                    ),
                  ) : Text(recordStr, style: const TextStyle(fontSize: 13)),
                  trailing: SizedBox(
                    width: 36,
                    height: 36,
                    child: IconButton(
                      icon: const Icon(Icons.star_border),
                      color: const Color(0xff3d3d3d),
                      onPressed: () => _cancelRecord(model)
                    ),
                  ),
                  onTap: ()  => _playVideo(model.api!, model.vid!),
                );
              },
          )
      ),
    );
  }

  void _playVideo(String api, String vid) {
    Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
      'videoId': vid,
      'api': api
    });
  }

  void _cancelRecord(RecordModel model) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('温馨提示'),
          content: const Text('确认取消收藏吗？'),
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
                final int i = await _db.updateRecord(model.id!, collected: 0);
                if (i > 0) {
                  _recordList.remove(model);
                  setState(() {});
                  BotToast.showText(text: '取消收藏成功');
                }
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
