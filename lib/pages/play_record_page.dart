import 'package:bot_toast/bot_toast.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:v_player/models/record_model.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/widgets/no_data.dart';

class PlayRecordPage extends StatefulWidget {
  const PlayRecordPage({Key? key}) : super(key: key);

  @override
  State<PlayRecordPage> createState() => _PlayRecordPageState();
}

class _PlayRecordPageState extends State<PlayRecordPage> {
  final DBHelper _db = DBHelper();
  final EasyRefreshController _controller = EasyRefreshController(
    controlFinishLoad: true
  );

  int _pageNum = -1; // 从0开始
  List<RecordModel> _recordList = [];

  Future<void> _getRecordList() async {
    final List<RecordModel> list = await _db.getRecordList(pageNum: _pageNum, played: true);
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
        title: const Text('播放记录'),
      ),
      body: EasyRefresh(
          controller: _controller,
          child: _recordList.isEmpty
            ? const NoData(tip: '没有播放记录',)
            : ListView.builder(
              itemCount: _recordList.length,
              itemBuilder: (context, index) {
                final RecordModel model = _recordList[index];
                String recordStr = '';
                if (model.anthologyName != null) {
                  recordStr += model.anthologyName!;
                }
                if (model.progress != null) {
                  if (model.progress! > 0.99) {
                    recordStr += '  ' + '播放完毕';
                  } else {
                    recordStr += '    ${(model.progress! * 100).toStringAsFixed(2)}%';
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
                    title: Text(model.name ?? '', style: const TextStyle(color: Colors.black, fontSize: 14), overflow: TextOverflow.ellipsis, maxLines: 2,),
                    subtitle: Text(recordStr, style: const TextStyle(fontSize: 12)),
                    trailing: SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        icon: const Icon(Icons.delete_forever),
                        color: const Color(0xff3d3d3d),
                        onPressed: () => _deleteRecord(model),
                      ),
                    ),
                    onTap: ()  => _playVideo(model.api!, model.vid!)
                );
              }
            ),
          onRefresh: () async {
            _pageNum = 0;
            await _getRecordList();
          },
          onLoad: () async {
            _pageNum++;
            await _getRecordList();
          }
      ),
    );
  }

  void _playVideo(String api, String vid) {
    Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
      'videoId': vid,
      'api': api
    });
  }

  Future<void> _deleteRecord(RecordModel model) async {
    if (model.id == null) return;
    final int i = await _db.deleteRecordById(model.id!);
    if (i > 0) {
      _recordList.remove(model);
      setState(() {});
      BotToast.showText(text: '删除成功');
    }
  }
}
