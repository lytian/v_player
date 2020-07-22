import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/pages/splash_page.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/provider/category.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/router/application.dart';
import 'package:v_player/router/routers.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp() {
    final router = Router();
    Routers.configureRouters(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    Color _themeColor;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider())
      ],
      child: Consumer<AppInfoProvider>(
        builder: (context, appInfo, _) {
          String colorKey = appInfo.themeColor;
          if (themeColorMap[colorKey] != null) {
            _themeColor = themeColorMap[colorKey];
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateRoute: Application.router.generator,
            theme: ThemeData.light().copyWith(
                primaryColor: _themeColor,
                accentColor: _themeColor,
                indicatorColor: Colors.white
            ),
            builder: BotToastInit(),
            home: SplashPage(),
          );
        },
      ),
    );
  }
}