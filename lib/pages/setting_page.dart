import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:m3u8_downloader/m3u8_downloader.dart';
import 'package:provider/provider.dart';
import 'package:v_player/common/constant.dart';
import 'package:v_player/provider/app_info.dart';
import 'package:v_player/utils/sp_helper.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  
  String? _colorKey;
  bool _wifiAutoDownload = true;
  bool _toMP4 = true;

  @override
  void initState() {
    super.initState();

    _colorKey = SpHelper.getString(Constant.keyThemeColor, defValue: 'blue');
    _wifiAutoDownload = SpHelper.getBool(Constant.keyWifiAutoDownload, defValue: true)!;
    _toMP4 = SpHelper.getBool(Constant.keyM3u8ToMp4)!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: <Widget>[
          ExpansionTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('主题'),
            initiallyExpanded: true,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: themeColorMap.keys.map((key) {
                    final Color? value = themeColorMap[key];
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
                        child: _colorKey == key ? const Icon(Icons.done, color: Colors.white,) : null,
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
          ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('WiFi自动下载'),
            trailing: Switch(
              value: _wifiAutoDownload,
              onChanged: (v) {
                setState(() {
                  _wifiAutoDownload = v;
                });
                SpHelper.putBool(Constant.keyWifiAutoDownload, v);
              }
            ),
            onTap: () {
              final bool v = !_wifiAutoDownload;
              setState(() {
                _wifiAutoDownload = v;
              });
              SpHelper.putBool(Constant.keyWifiAutoDownload, v);
            },
          ),
          ListTile(
            leading: const Icon(Icons.crop),
            title: const Text('M3U8转MP4'),
            trailing: Switch(
              value: _toMP4,
              onChanged: _toggleConvertMp4,
            ),
            onTap: () {
              _toggleConvertMp4(!_toMP4);
            },
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text('清空缓存'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              BotToast.showText(text: '待开发');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleConvertMp4(bool flag) async {
    try {
      await M3u8Downloader.config(convertMp4: flag);
      setState(() {
        _toMP4 = flag;
      });
      SpHelper.putBool(Constant.keyM3u8ToMp4, flag);
    } catch(err) {
      BotToast.showText(text: '设置失败');
    }
  }
}
