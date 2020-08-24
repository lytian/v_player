import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:v_player/models/record_model.dart';
import 'package:v_player/router/application.dart';
import 'package:v_player/router/routers.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/fluro_convert_util.dart';
import 'package:v_player/widgets/no_data.dart';

class CollectionPage extends StatefulWidget {
  @override
  _CollectionPageState createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  DBHelper _db = DBHelper();
  EasyRefreshController _controller = EasyRefreshController();

  int _pageNum = -1; // 从0开始
  List<RecordModel> _recordList = [];

  Future<int> _getRecordList() async {
    List list = await _db.getRecordList(pageNum: _pageNum, pageSize: 20, collected: 1);
    if (!mounted) return 0;
    setState(() {
      if (_pageNum <= 0) {
        _recordList = list;
      } else {
        _recordList += list;
      }
    });
    return list.length;
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
        title: Text('我的收藏'),
      ),
      body: EasyRefresh.custom(
        controller: _controller,
        firstRefresh: true,
        firstRefreshWidget: Center(
          child: CircularProgressIndicator(),
        ),
        slivers: <Widget>[
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              RecordModel model = _recordList[index];
              String recordStr = '';
              if (model.progress > 0) {
                if (model.anthologyName != null) {
                  recordStr += model.anthologyName;
                }
                if (model.progress > 0.99) {
                  recordStr += ' ' + '播放完毕';
                } else {
                  recordStr = '播放至：' + recordStr + ' ' + (model.progress * 100).toStringAsFixed(2);
                }
              }
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: FadeInImage.assetNetwork(
                    placeholder: 'assets/image/placeholder-l.jpg',
                    image: model.pic,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 75,
                  ),
                ),
                title: Text(model.name, style: TextStyle(color: Colors.black, fontSize: 15), overflow: TextOverflow.ellipsis, maxLines: 2,),
                subtitle: recordStr.isEmpty ? RichText(
                  text: TextSpan(
                      style: TextStyle(fontSize: 13, color: Color(0xff666666)),
                      children: [
                        TextSpan(text: model.type),
                        TextSpan(text: '  暂无播放', style: TextStyle(color: Color(0xff999999)))
                      ]
                  ),
                ) : Text(recordStr, style: TextStyle(fontSize: 13)),
                isThreeLine: false,
                trailing: SizedBox(
                  width: 36,
                  height: 36,
                  child: IconButton(
                    icon: Icon(Icons.star_border),
                    color: Color(0xff3d3d3d),
                    onPressed: () => _cancelRecord(model)
                  ),
                ),
                onTap: ()  => _playVideo(model.api, model.vid),
              );
            },
              childCount: _recordList.length,
            ),
          )
        ],
        emptyWidget: _recordList.length == 0
            ? NoData(tip: '没有找到视频',)
            : null,
        header: ClassicalHeader(
            refreshText: '下拉刷新',
            refreshReadyText: '释放刷新',
            refreshingText: '正在刷新...',
            refreshedText: '已获取最新数据',
            infoText: '更新于%T'),
        footer: ClassicalFooter(
            loadText: '上拉加载',
            loadReadyText: '释放加载',
            loadingText: '正在加载',
            loadedText: '已加载结束',
            noMoreText: '没有更多数据了~',
            infoText: '更新于%T'),
        onRefresh: () async {
          _pageNum = 0;
          await _getRecordList();
        },
        onLoad: () async {
          _pageNum++;
          int len = await _getRecordList();
          if (len < 20) {
            _controller.finishLoad(noMore: true);
          }
        }
      ),
    );
  }

  void _playVideo(String api, String vid) {
    Application.router.navigateTo(context, Routers.detailPage + '?api=${FluroConvertUtils.fluroCnParamsEncode(api)}&id=$vid');
  }

  void _cancelRecord(RecordModel model) {
    showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('温馨提示'),
            content: Text('确认取消收藏吗？'),
            actions: <Widget>[
              FlatButton(
                child: Text('取消'),
                textColor: Colors.grey,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('确定'),
                onPressed: () async {
                  int i = await _db.updateRecord(model.id, collected: 0);
                  if (i > 0) {
                    _recordList.remove(model);
                    setState(() {});
                    BotToast.showText(text: '取消收藏成功');
                  }
                  Navigator.of(context).pop();
                },
              )
            ],
          );
        }
    );
  }
}
