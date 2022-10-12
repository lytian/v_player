import 'package:bot_toast/bot_toast.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/provider/category.dart';
import 'package:v_player/provider/download_task.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/application.dart';

void main() {
  runApp(const MyApp());

  // 全局设置EasyRefresh
  EasyRefresh.defaultHeaderBuilder = () => const MaterialHeader();
  EasyRefresh.defaultFooterBuilder = () => const ClassicFooter(
    dragText: '上拉加载',
    armedText: '释放加载',
    readyText: '正在加载...',
    processingText: '正在加载...',
    processedText: '加载完成',
    noMoreText: '没有更多数据',
    failedText: '加载失败',
    messageText: '更新于 %T',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color? themeColor;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadTaskProvider(context)),
      ],
      child: Consumer<AppInfoProvider>(
        builder: (context, appInfo, _) {
          final String colorKey = appInfo.themeColor;
          if (themeColorMap[colorKey] != null) {
            themeColor = themeColorMap[colorKey];
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              primaryColor: themeColor,
              indicatorColor: Colors.white,
              appBarTheme: AppBarTheme(
                backgroundColor: themeColor,
              ),
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
