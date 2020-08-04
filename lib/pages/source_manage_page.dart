import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/db_helper.dart';

class SourceManagePage extends StatefulWidget {
  @override
  _SourceManagePageState createState() => _SourceManagePageState();
}

class _SourceManagePageState extends State<SourceManagePage> {
  DBHelper _db = DBHelper();
  List<SourceModel> _sourceList = [];
  SourceModel _currentSource;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 200), () async {
      List list = await _db.getSourceList();
      setState(() {
        _sourceList = list;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _db.close();
  }

  @override
  Widget build(BuildContext context) {
    final curSource = context.select<SourceProvider, SourceModel>((value) => value.currentSource);

    return Scaffold(
      appBar: AppBar(
        title: Text('资源管理'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              print('1111111111');
            },
          )
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        itemCount: _sourceList.length,
        itemBuilder: (context, index) {
          SourceModel model = _sourceList[index];
          return ListTile(
            title: Text(model.name, style: TextStyle(
              color: curSource != null && curSource.id == model.id ? Colors.red : Colors.black,
              fontSize: 18
            ),),
            subtitle: Text(model.type),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () async {
                    if (await canLaunch(model.url)) {
                      await launch(model.url);
                    } else {
                      BotToast.showText(text: '不能打开${model.url}');
                    }
                  },
                ),
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.delete_sweep),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('提示'),
                          content: Text('确认删除资源【${model.name}】吗？'),
                          actions: [
                            FlatButton(
                              child: Text('取消'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            FlatButton(
                              child: Text('确定'),
                              onPressed: () async {
                                int res = await _db.deleteSourceById(model.id);
                                if (res > 0) {
                                  BotToast.showText(text: '删除成功！');
                                } else {
                                  BotToast.showText(text: '删除成功！');
                                }
                                Navigator.pop(context);
                                List list = await _db.getSourceList();
                                setState(() {
                                  _sourceList = list;
                                });
                              },
                            )
                          ],
                        );
                      }
                    );
                  },
                ),
              ],
            ),
            onTap: () {
              // 切换视频源
              if (curSource != null && curSource.id == model.id) return;

              context.read<SourceProvider>().setCurrentSource(model, context);
              Navigator.pop(context);
            },
          );
        },
        separatorBuilder: (context, index) {
          return Divider();
        },
      ),
    );
  }
}
