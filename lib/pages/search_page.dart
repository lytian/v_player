import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/http_util.dart';
import 'package:v_player/widgets/no_data.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    Key? key,
    this.searchText,
    this.hintText,
  }) : super(key: key);

  final String? searchText;
  final String? hintText;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final EasyRefreshController _controller = EasyRefreshController();
  int _pageNum = 1;
  bool _loading = false;
  List<VideoModel> _videoList = [];

  @override
  void initState() {
    super.initState();

    _searchController.text = widget.searchText ?? '';
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: const BackButton(
          color: Colors.black,
        ),
        title: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          autofocus: true,
          style: const TextStyle(
            fontSize: 16,
          ),
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            isCollapsed: true,
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            hintText: widget.hintText ?? '搜索资源~',
            hintStyle: const TextStyle(color: Color(0xFFCCCCCC)),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isEmpty ? null : GestureDetector(
              onTap: () {
                _searchController.clear();
              },
              child: const Icon(
                Icons.cancel,
                size: 24,
                color: Color(0xFF999999),
              ),
            ),
          ),
          onSubmitted: (val) {
            if (_searchController.text.isEmpty) {
              setState(() {
                _videoList = [];
              });
              return;
            }
            setState(() {
              _loading = true;
              _pageNum = 1;
            });
            _search().whenComplete(() => setState(() {
              _loading = false;
            }));
          },
        ),
      ),
      body: _loading ? const Center(
          child: CircularProgressIndicator()
        ) : EasyRefresh(
          controller: _controller,
          child: _videoList.isEmpty ? const NoData(tip: '没有搜索视频~~') : (
            ListView.builder(
              padding: const EdgeInsets.all(4),
              itemCount: _videoList.length,
              itemBuilder: (BuildContext context, int index) {
                final video = _videoList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
                      'videoId': video.id,
                    });
                  },
                  child: Container(
                    height: 92,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3)
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: CachedNetworkImage(
                              width: 96,
                              height: 72,
                              imageUrl: video.pic ?? '',
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Image.asset('assets/image/placeholder-l.jpg', fit: BoxFit.cover,),
                              errorWidget: (context, url, dynamic error) => Container(
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage('assets/image/placeholder-l.jpg'),
                                      fit: BoxFit.cover
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
                              ),
                            )
                        ),
                        const SizedBox(width: 10,),
                        Expanded(child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(video.name ?? '暂无标题', style: const TextStyle(color: Colors.black, fontSize: 16), overflow: TextOverflow.ellipsis, maxLines: 2,),
                            Text(video.note ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        )),
                        const SizedBox(width: 10,),
                        const Icon(Icons.play_circle_outline, size: 30, color: Colors.grey,)
                      ],
                    ),
                  ),
                );
              }
            )
          ),
          onRefresh: () async {
            _pageNum = 1;
            await _search();
          },
          onLoad: () async {
            _pageNum++;
            await _search();
          }
        ),
    );
  }

  Future<void> _search() async {
    final list = await HttpUtil().getVideoList(
      keyword: _searchController.text,
      pageNum: _pageNum,
    );
    setState(() {
      if (_pageNum <= 1) {
        _videoList = list;
      } else {
        _videoList += list;
      }
    });
    _controller.finishLoad(list.length < 20 ? IndicatorResult.noMore : IndicatorResult.success);
  }
}
