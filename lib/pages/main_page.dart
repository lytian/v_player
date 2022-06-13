import 'package:flutter/material.dart';
import 'package:flutter_easyrefresh/easy_refresh.dart';
import 'package:provider/provider.dart';
import 'package:v_player/models/category_model.dart';
import 'package:v_player/models/source_model.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/pages/main_left_page.dart';
import 'package:v_player/pages/search_bar.dart';
import 'package:v_player/provider/source.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/http_util.dart';
import 'package:v_player/widgets/animated_floating_action_button.dart';
import 'package:v_player/widgets/no_data.dart';
import 'package:v_player/widgets/video_item.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with TickerProviderStateMixin {
  // 滚动控制器
  late TabController _navController;
  List<CategoryModel> _categoryList = [];
  String? _type = '';
  bool _isLandscape = false; // 是否横屏

  late EasyRefreshController _controller;
  int _pageNum = 1;
  List<VideoModel> _videoList = [];
  SourceModel? _currentSource;
  late SourceProvider _sourceProvider;
  final GlobalKey<AnimatedFloatingActionButtonState> _buttonKey = GlobalKey<AnimatedFloatingActionButtonState>();
  bool _firstLoading = false;

  @override
  void initState() {
    super.initState();

    _navController = TabController(length: _categoryList.length, vsync: this);
    _controller = EasyRefreshController();

    // 资源变化监听
    _sourceProvider = context.read<SourceProvider>();
    _currentSource = _sourceProvider.currentSource;
    _sourceProvider.addListener(() {
      if (!mounted) return;

      setState(() {
        _videoList = [];
        _currentSource = _sourceProvider.currentSource;
      });

      _initData();
    });

    _initData();
  }

  /// 获取分类
  Future<void> _getCategoryList() async {
    if (!mounted) return;
    // 初始化一些数据
    _navController.dispose();
    setState(() {
      _type = '';
      _categoryList = [];
      _navController = TabController(length: _categoryList.length, vsync: this);
    });
    final List<CategoryModel> list = await HttpUtil().getCategoryList();
    if (list.isNotEmpty) {
      setState(() {
        _categoryList = [CategoryModel(id: '', name: '最新')] + list;
        _navController = TabController(length: _categoryList.length, vsync: this);
      });
    }
  }

  /// 获取视频列表
  Future<int> _getVideoList() async {
    int? hour; // 最近几个小时更新
    if (_type == null || _type!.isEmpty) {
      hour = 72;
    }
    final List<VideoModel> videos = await HttpUtil().getVideoList(pageNum: _pageNum, type: _type, hour: hour);
    if (!mounted) return 0;
    setState(() {
      if (_pageNum <= 1) {
        _videoList = videos;
      } else {
        _videoList += videos;
      }
    });
    return videos.length;
  }

  Future<void> _initData() async {
    setState(() {
      _firstLoading = true;
      _pageNum = 1;
    });
    await _getCategoryList();
    await _getVideoList();

    setState(() {
      _firstLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (BuildContext ctx) {
          return IconButton(
            icon: Container(
              width: 34,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                image: DecorationImage(
                  fit: BoxFit.fill,
                  image: AssetImage('assets/image/avatar.png'),
                ),
              ),
            ),
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            });
        }),
        centerTitle: true,
        title: Text(_currentSource != null
            ? (_currentSource!.name ?? '')
            : '没找到视频源'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (_currentSource == null) return;
              showSearch(context: context, delegate: SearchBarDelegate(hintText: '搜索【${_currentSource!.name}】的资源'));
            },
          )
        ],
        bottom: _buildCategoryNav(),
      ),
      body: !_firstLoading ? _buildVideoList() : const Center(
        child: CircularProgressIndicator()
      ),
      floatingActionButton: AnimatedFloatingActionButton(
        key: _buttonKey,
        onPress: () {
          Navigator.of(context).pushNamed(Application.sourceManagePage);
        },
      ),
      drawer: const Drawer(
        child: MainLeftPage(),
      ),
    );
  }

  PreferredSize _buildCategoryNav() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _categoryList.isNotEmpty ? TabBar(
              controller: _navController,
              isScrollable: true,
              tabs: _categoryList.map((e) => Tab(text: e.name,)).toList(),
              onTap: (index) {
                _type = _categoryList[index].id;
                _pageNum = 0;
                _controller.callRefresh();
              },
            ) : Container()
          ),
          Container(
            height: 20,
            margin: const EdgeInsets.only(left: 4),
            child: VerticalDivider(
              color: Colors.grey[200],
            ),
          ),
          Container(
              width: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: Icon(_isLandscape ? Icons.list : Icons.table_chart),
                padding: const EdgeInsets.all(4),
                color: Colors.white,
                onPressed: () {
                  setState(() {
                    _isLandscape = !_isLandscape;
                  });
                },
              )
          )
        ],
      ),
    );
  }

  Widget _buildVideoList() {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.dragDetails != null && _buttonKey.currentState != null) {
          if (notification.dragDetails!.delta.dy < 0 && _buttonKey.currentState!.isShow) {
            _buttonKey.currentState!.hide();
          } else if (notification.dragDetails!.delta.dy > 0 && !_buttonKey.currentState!.isShow) {
            _buttonKey.currentState!.show();
          }
        }
        return false;
      },
      child: EasyRefresh.custom(
          controller: _controller,
          slivers: <Widget>[
            if (_isLandscape)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return VideoItem(video: _videoList[index], type: 1,);
                },
                  childCount: _videoList.length,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return VideoItem(video: _videoList[index],);
                  },
                    childCount: _videoList.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 8,
                      childAspectRatio: 9 / 15
                  ),
                ),
              )
          ],
          emptyWidget: _videoList.isEmpty
              ? const NoData(tip: '没有找到视频',)
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
            final int len = await _getVideoList();
            if (len < 20) {
              _controller.finishLoad(noMore: true);
            }
          })
    );
  }
}
