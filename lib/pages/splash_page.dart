import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/sp_helper.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final DBHelper _db = DBHelper();
  Timer? _timer;
  int _count = 3; // 倒计时秒数

  @override
  void initState() {
    super.initState();
    _initAsync();
  }
  Future<void> _initAsync() async {
    await SpHelper.getInstance();
    final String colorKey = SpHelper.getString(Constant.keyThemeColor, defValue: Constant.defaultThemeColor);
    // 设置初始化主题颜色
    if (!mounted) return;
    context.read<AppInfoProvider>().setTheme(colorKey);
    // 加载默认资源
    final Map<String, dynamic>? source = SpHelper.getObject(Constant.keyCurrentSource) as Map<String, dynamic>?;
    if (source == null) {
      final String sourceJson = await DefaultAssetBundle.of(context).loadString("assets/data/source.json");
      final List<dynamic> jsonList = json.decode(sourceJson) as List<dynamic>;
      List<SourceModel> list = jsonList.map((dynamic e) => SourceModel.fromJson(e)).toList();
      await _db.insertBatchSource(list);
      list = await _db.getSourceList();
      if (!mounted) return;
      context.read<SourceProvider>().setCurrentSource(list[0], context);
    } else {
      context.read<SourceProvider>().setCurrentSource(SourceModel.fromJson(source), context);
    }
    // 删除30天以前的播放记录
    _db.deleteAgoRecord(DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch);

    // 倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_count <= 1) {
          _timer?.cancel();
          _timer = null;
          _goMain();
        } else {
          _count -= 1;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _db.close();
    super.dispose();
  }

  // 跳转主页
  void _goMain() {
    Navigator.of(context).pushReplacementNamed(Application.mainPage);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        child: Stack(
  //      fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
          'assets/image/splash-bg.jpg',
            width: double.infinity,
            fit: BoxFit.fill,
            height: double.infinity,
          ),
          Positioned(
            bottom: 30,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _goMain();
              },
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                      border: Border.all(width: 0.33, color: Colors.grey)
                  ),
                  child: Text(
                    '$_count 跳转',
                    style: const TextStyle(fontSize: 14.0, color: Colors.white),
                  )
              ),
            ),
          )
        ],
      )
    );
  }
}
