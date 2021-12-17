import 'package:flutter/material.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/utils/sp_helper.dart';

class AppInfoProvider with ChangeNotifier {
  String _themeColor = '';

  String get themeColor => _themeColor;

  void setTheme(String themeColor) {
    _themeColor = themeColor;
    SpHelper.putString(Constant.keyThemeColor, themeColor);
    notifyListeners();
  }
}
