import 'package:flutter/material.dart';

class AppInfoProvider with ChangeNotifier {
  String _themeColor = '';

  String get themeColor => _themeColor;

  void setTheme(String themeColor) {
    _themeColor = themeColor;
    notifyListeners();
  }
}