import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:provider/provider.dart';
import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/pages/main_left_page.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:v_player/widgets/video_item.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin{
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // 滚动控制器
  TabController _navController;
  List<CategoryModel> _categoryList = [];
  String _type = '';
  bool _isLanscape = false; // 是否横屏

  EasyRefreshController _controller;
  int _pageNum = 1;
  List _videoList = [];
  SourceModel _currentSource;
  SourceProvider _sourceProvider;

  @override
  void initState() {
    super.initState();

    _navController = TabController(length: _categoryList.length, vsync: this);
    _controller = EasyRefreshController();

    // 资源变化监听
    _sourceProvider = context.read<SourceProvider>();
    _currentSource = _sourceProvider.currentSource;
    _sourceProvider.addListener(() {
      print('-----------------------');
      setState(() {
        _videoList = [];
      });
      _getCategoryList();
      _controller.callRefresh();
    });

    _getCategoryList();
    _getVideoList();
  }

  /// 获取分类
  void _getCategoryList() async {
    List<CategoryModel> list = await HttpUtils.getCategoryList();
    setState(() {
      _categoryList = [CategoryModel(id: '', name: '全部')] + list;
      _navController?.dispose();
      _navController = TabController(length: _categoryList.length, vsync: this);
    });
  }

  /// 获取视频列表
  Future<void> _getVideoList() async {
    List<VideoModel> videos = await HttpUtils.getVideoList(pageNum: _pageNum, type: _type);
    setState(() {
      if (this._pageNum == 1) {
        _videoList = videos;
      } else {
        _videoList += videos;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: InkWell(
          child: Container(
            margin: EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/image/avatar.png'),
            ),
          ),
          onTap: () {
            _scaffoldKey.currentState.openDrawer();
          },
        ),
        centerTitle: true,
        title: Text(_currentSource != null
            ? _currentSource.name
            : '没找到视频源'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            padding: EdgeInsets.all(4),
            onPressed: () {
              if (_currentSource == null) return;
//              showSearch(context: context, delegate: SearchBarDelegate(hintText: '搜索【${_currentSource.name}】的资源'));
            },
          )
        ],
        bottom: _buildCategoryNav(),
      ),
      body: _buildVideoList(),
      drawer: Drawer(
        child: MainLeftPage(),
      ),
    );
  }

  Widget _buildCategoryNav() {
    return PreferredSize(
      preferredSize: Size.fromHeight(40),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: _categoryList.isNotEmpty ? TabBar(
              controller: _navController,
              isScrollable: true,
              tabs: _categoryList.map((e) => Tab(text: e.name,)).toList(),
              onTap: (index) {
                this._type = _categoryList[index].id;
                this._controller.callRefresh();
              },
            ) : Container()
          ),
          IconButton(
            icon: Icon(_isLanscape ? Icons.list : Icons.table_chart),
            color: Colors.white,
            onPressed: () {
              setState(() {
                _isLanscape = !_isLanscape;
              });
            },
          )
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return EasyRefresh.custom(
        controller: _controller,
        firstRefresh: true,
        // 首次加载
        firstRefreshWidget: Center(
            child: SizedBox(
              height: 200.0,
              width: 300.0,
              child: Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 50.0,
                      height: 50.0,
                      child: CircularProgressIndicator(),
                    ),
                    Container(
                      child: Text('加载中...'),
                    )
                  ],
                ),
              ),
            )),
        slivers: <Widget>[
          _isLanscape
            ? SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                  VideoModel video = _videoList[index];
                  return LandscapeVideoItem(video);
                },
                childCount: _videoList.length,
              ),
            )
            : SliverPadding(
              padding: EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  VideoModel video = _videoList[index];
                  return PortraitVideoItem(video);
                },
                  childCount: _videoList.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 8,
                    childAspectRatio: 9 / 15
                ),
              ),
            )
        ],
        emptyWidget: _videoList.length == 0
            ? Container(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: SizedBox(),
                flex: 2,
              ),
              SizedBox(
                width: 100.0,
                height: 100.0,
                child: Image.asset('assets/image/nodata.png'),
              ),
              Text(
                '没有找到视频',
                style: TextStyle(fontSize: 16.0, color: Colors.grey[400]),
              ),
              Expanded(
                child: SizedBox(),
                flex: 3,
              ),
            ],
          ),
        )
            : null,
        header: ClassicalHeader(
            refreshText: '下拉刷新',
            refreshReadyText: '释放刷新',
            refreshingText: '正在刷新...',
            refreshedText: '已获取最新数据',
            infoText: '更新于%T'),
        footer: ClassicalFooter(
            loadText: '上拉加载',
            loadReadyText: '释放加载',
            loadingText: '正在加载',
            loadedText: '已加载结束',
            noMoreText: '没有更多数据了~',
            infoText: '更新于%T'),
        onRefresh: () async {
          _pageNum = 1;
          await _getVideoList();
        },
        onLoad: () async {
          _pageNum++;
          await _getVideoList();
        });
  }
}
