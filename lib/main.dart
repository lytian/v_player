import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/provider/category.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/application.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    Color? _themeColor;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadTaskProvider(context)),
      ],
      child: Consumer<AppInfoProvider>(
        builder: (context, appInfo, _) {
          String colorKey = appInfo.themeColor;
          if (themeColorMap[colorKey] != null) {
            _themeColor = themeColorMap[colorKey];
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primaryColor: _themeColor,
              accentColor: _themeColor,
              indicatorColor: Colors.white,
              appBarTheme: AppBarTheme(brightness: Brightness.dark)
            ),
            builder: BotToastInit(),
            navigatorObservers: [
              BotToastNavigatorObserver(),
            ],
            navigatorKey: Application.navigatorKey,
            initialRoute: Application.splashPage,
            onGenerateRoute: Application.generateRoute,
          );
        },
      ),
    );
  }
}