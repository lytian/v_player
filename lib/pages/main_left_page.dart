import 'package:flutter/material.dart';

class MainLeftPage extends StatefulWidget {
  @override
  _MainLeftPageState createState() => _MainLeftPageState();
}

class _MainLeftPageState extends State<MainLeftPage> {

  List<_ListItemInfo> _items = <_ListItemInfo>[
    new _ListItemInfo('download', '下载记录', Icons.file_download),
    new _ListItemInfo('collection', '我的收藏', Icons.star),
    new _ListItemInfo('setting', '设置', Icons.settings),
    new _ListItemInfo('about', '关于', Icons.info),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        UserAccountsDrawerHeader(
          currentAccountPicture: CircleAvatar(
            backgroundImage: AssetImage('assets/image/avatar.png'),
          ),
          accountName: Text('单身汪', style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          accountEmail: Text('别看了，臭屌丝。有本事充钱啊！',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white
            ),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            removeTop: true,
            context: context,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (BuildContext context, int index) {
                _ListItemInfo item = _items[index];
                return ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.title),
                    onTap: () {
//                    switch (item.id) {
//                      case 'download':
//                        Application.router.pop(context);  // 先关闭Drawer
//                        Application.router.navigateTo(context, Routers.downloadPage);
//                        break;
//                      case 'setting':
//                        Application.router.pop(context);  // 先关闭Drawer
//                        Application.router.navigateTo(context, Routers.settingPage);
//                        break;
//                      case 'about':
//                        Application.router.pop(context);  // 先关闭Drawer
//                        Application.router.navigateTo(context, Routers.aboutPage);
//                        break;
//                      default:
//                        break;
//                    }
                    }
                );
              },
            ),
          )
        ),
      ],
    );
  }
}

class _ListItemInfo {
  final String id;
  final String title;
  final IconData icon;
  final Widget page;
  final bool withScaffold;

  _ListItemInfo(this.id, this.title, this.icon, [this.page, this.withScaffold = true]);
}