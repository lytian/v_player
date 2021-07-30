import 'dart:convert';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _menuList = [
    { "value": 0, "label": "添加资源" },
    { "value": 1, "label": "从剪贴板导入" },
    { "value": 2, "label": "导出到剪贴板" },
  ];

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(milliseconds: 200), () async {
      List<SourceModel> list = await _db.getSourceList();
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
    final curSource = context.select<SourceProvider, SourceModel?>((value) => value.currentSource);

    return Scaffold(
      appBar: AppBar(
        title: Text('资源管理'),
        actions: <Widget>[
          PopupMenuButton(
            offset: Offset(0, 56),
            onSelected: (v) {
              switch (v) {
                case 0:
                  // 添加资源
                  _showFormDialog(null);
                  break;
                case 1:
                  // 导入资源
                  _importSource();
                  break;
                case 2:
                  // 导出资源
                  _exportSource();
                  break;
              }
            },
            itemBuilder: (context) {
              return _menuList.map((e) {
                return PopupMenuItem(
                  value: e["value"],
                  child: Text(e['label']),
                );
              }).toList();
            },
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: ListView.separated(
        itemCount: _sourceList.length,
        itemBuilder: (context, index) {
          SourceModel model = _sourceList[index];
          return ListTile(
            title: Text(model.name ?? '', style: TextStyle(
              color: curSource != null && curSource.id == model.id ? Colors.red : Colors.black,
              fontSize: 18
            ),),
            subtitle: Text(model.type ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.camera),
                  onPressed: () async {
                    if (model.url == null) {
                      BotToast.showText(text: '空地址');
                      return;
                    }
                    if (await canLaunch(model.url!)) {
                      await launch(model.url!);
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
                  onPressed: () => _deleteSource(model, curSource != null && curSource.id == model.id),
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

  /// 显示表单
  /// model 为null时，添加，不为null时修改
  void _showFormDialog(SourceModel? model) {

  }

  /// 导入资源
  void _importSource() async {
    var content = await Clipboard.getData(Clipboard.kTextPlain);
    if (content == null || content.text == null || content.text!.isEmpty) {
      BotToast.showText(text: '剪贴板内容为空！');
      return;
    }
    try {
      String jsonStr = content.text!;
      int count = 0;
      if (jsonStr.indexOf('[') > -1 && jsonStr.indexOf(']') > -1) {
        // 多个
        List<dynamic> list = json.decode(jsonStr);
        List<SourceModel> sourceList = list.map((e) => SourceModel.fromJson(e)).toList();
        // 去重
        _sourceList.forEach((source) {
          int index = sourceList.indexWhere((e) => e.name == source.name);
          if (index > -1)
            sourceList.removeAt(index);
        });
        count = await _db.insertBatchSource(sourceList);
      } else {
        // 单个
        SourceModel source = SourceModel.fromJson(json.decode(jsonStr));
        if (_sourceList.indexWhere((e) => e.name == source.name) > -1) {
          BotToast.showText(text: '资源已存在');
          return;
        }
        count = await _db.insertSource(source);
      }
      if (count <= 0) {
        BotToast.showText(text: '导入失败！');
        return;
      }
      List<SourceModel> list = await _db.getSourceList();
      setState(() {
        _sourceList = list;
      });

    } catch(e) {
      print(e);
      BotToast.showText(text: '数据解析失败！');
    }
  }

  /// 导出资源到剪贴板
  void _exportSource() {
    try {
      Clipboard.setData(ClipboardData(text: json.encode(_sourceList)));
      BotToast.showText(text: '导出成功！');
    } catch(e) {
      print(e);
      BotToast.showText(text: '导出资源到剪贴板失败！');
    }
  }

  /// 删除资源
  void _deleteSource(SourceModel model, bool isCurrent) async {
    if (_sourceList.length <= 1) {
      BotToast.showText(text: '这已经是最后一个资源了，不能删除！');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('提示'),
          content: Text('确认删除资源【${model.name}】吗？'),
          actions: [
            TextButton(
              child: Text('取消', style: TextStyle(
                color: Colors.grey
              ),),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('确定'),
              onPressed: () async {
                int res = await _db.deleteSourceById(model.id!);
                if (res > 0) {
                  BotToast.showText(text: '删除成功！');
                } else {
                  BotToast.showText(text: '删除失败！');
                }
                Navigator.pop(context);
                List<SourceModel> list = await _db.getSourceList();
                if (isCurrent && list.length > 0) {
                  context.read<SourceProvider>().setCurrentSource(list[0], context);
                }
                setState(() {
                  _sourceList = list;
                });
              },
            )
          ],
        );
      }
    );
  }
}
