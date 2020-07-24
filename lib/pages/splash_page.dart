import 'dart:async';
import 'dart:convert';

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/router/application.dart';
import 'package:v_player/router/routers.dart';
import 'package:v_player/utils/db_helper.dart';
import 'package:v_player/utils/sp_helper.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  DBHelper _db = DBHelper();
  Timer _timer;
  int _count = 3; // 倒计时秒数

  @override
  void initState() {
    super.initState();
    _initAsync();
  }
  void _initAsync() async {
    await SpHelper.getInstance();
    String colorKey = SpHelper.getString(Constant.key_theme_color, defValue: Constant.default_theme_color);
    // 设置初始化主题颜色
    context.read<AppInfoProvider>().setTheme(colorKey);
    // 加载默认资源
    Map<String, dynamic> source = SpHelper.getObject(Constant.key_current_source);
    if (source == null) {
      String sourceJson = await DefaultAssetBundle.of(context).loadString("assets/data/source.json");
      List<dynamic> jsonList = json.decode(sourceJson);
      List<SourceModel> list = jsonList.map((e) => SourceModel.fromJson(e)).toList();
      await _db.insertBatchSource(list);
      source = jsonList[0];
    }
    context.read<SourceProvider>().setCurrentSource(SourceModel.fromJson(source), context);

    // 倒计时
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_count <= 1) {
          _timer.cancel();
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
    _db?.close();
    super.dispose();
  }

  // 跳转主页
  void _goMain() {
    Application.router.navigateTo(context, Routers.mainPage, clearStack: true, transition: TransitionType.fadeIn);
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    '$_count 跳转',
                    style: TextStyle(fontSize: 14.0, color: Colors.white),
                  ),
                  decoration: BoxDecoration(
                      color: Color(0x66000000),
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                      border: Border.all(width: 0.33, color: Colors.grey)
                  )
              ),
            ),
          )
        ],
      )
    );
  }
}
