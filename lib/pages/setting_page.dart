import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/utils/sp_helper.dart';

class SettingPage extends StatefulWidget {
  @override
  _SettingPageState createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  
  String _colorKey;
  bool _wifiAutoDownload = true;

  @override
  void initState() {
    super.initState();

    _colorKey = SpHelper.getString(Constant.key_theme_color, defValue: 'blue');
    _wifiAutoDownload = SpHelper.getBool(Constant.key_wifi_auto_download, defValue: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
      ),
      body: ListView(
        children: <Widget>[
          ExpansionTile(
            leading: Icon(Icons.color_lens),
            title: Text('主题'),
            initiallyExpanded: true,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: themeColorMap.keys.map((key) {
                      Color value = themeColorMap[key];
                      return InkWell(
                        onTap: () {
                          setState(() {
                           _colorKey = key; 
                          });
                          context.read<AppInfoProvider>().setTheme(key);
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          color: value,
                          child: _colorKey == key ? Icon(Icons.done, color: Colors.white,) : null,
                        ),
                      );
                    }).toList(),
                  ),
              )
            ],
          ),
          ListTile(
            leading: Icon(Icons.wifi),
            title: Text('WiFi自动下载'),
            trailing: Switch(
              value: _wifiAutoDownload,
              onChanged: (v) {
                setState(() {
                  _wifiAutoDownload = v;
                });
                SpHelper.putBool(Constant.key_wifi_auto_download, v);
              }
            ),
          )
        ],
      ),
    );
  }
}