import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
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

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
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
      hour = 24 * 7;
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
    try {
      await _getCategoryList();
      await _getVideoList();
    } catch (err) {
      rethrow;
    }

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
              showSearch(
                useRootNavigator: true,
                context: context,
                delegate: SearchBarDelegate(hintText: '搜索【${_currentSource!.name}】的资源')
              );
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
      child: EasyRefresh(
          controller: _controller,
          child: _videoList.isEmpty ? const NoData(tip: '没有视频数据~') : (
              _isLandscape ? ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: _videoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildVideoItem(_videoList[index], true);
                  }
                ) : MasonryGridView.count(
                  padding: const EdgeInsets.all(4),
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  itemCount: _videoList.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildVideoItem(_videoList[index], false);
                  },
                )
            ),
          onRefresh: () async {
            _pageNum = 1;
            await _getVideoList();
          },
          onLoad: () async {
            _pageNum++;
            final int len = await _getVideoList();
            if (len < 20) {
              _controller.finishLoad(IndicatorResult.noMore);
            }
          })
    );
  }

  Widget _buildVideoItem(VideoModel video, bool isLandscape) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
          'videoId': video.id,
        });
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                if (isLandscape) AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: video.pic ?? '',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Image.asset('assets/image/placeholder-l.jpg', fit: BoxFit.cover,),
                    errorWidget: (context, url, error) => AspectRatio(
                      aspectRatio: isLandscape ? 16 / 9 : 3 / 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/image/placeholder-l.jpg'),
                              fit: BoxFit.cover
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
                      ),
                    ),
                  ),
                ) else CachedNetworkImage(
                  imageUrl: video.pic ?? '',
                  placeholder: (context, url) => AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.asset('assets/image/placeholder-p.jpg', fit: BoxFit.cover,),
                  ),
                  errorWidget: (context, url, error) => AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/image/placeholder-p.jpg'),
                          fit: BoxFit.cover
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
                    ),
                  ),
                ),
                if (video.note != null && video.note!.isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(125),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(5),
                        ),
                      ),
                      child: Text(video.note!, overflow: TextOverflow.ellipsis, style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),),
                    ),
                  ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                video.name ?? '',
                style: const TextStyle(fontSize: 15),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
