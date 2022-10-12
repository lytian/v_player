import 'package:flutter/material.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/application.dart';
import 'package:v_player/utils/http_util.dart';
import 'package:v_player/widgets/no_data.dart';
import 'package:v_player/widgets/video_item.dart';

class SearchBarDelegate extends SearchDelegate<String> {

  SearchBarDelegate({
    String? hintText,
  }) : super(
      searchFieldLabel: hintText
  );

  // final List<String> _suggestList = [];
  Future<List<VideoModel>>? _future;

  Future<List<VideoModel>> _getSearchResult(String? str) async {
    if (str == null || str == '') return [];

    return HttpUtil().getVideoList(keyword: str);
  }

  Widget _buildText(String str) {
    return Center(
      child: Text(str, style: const TextStyle(
        color: Colors.redAccent,
        fontSize: 16
      )),
    );
  }

  //重写右侧的图标
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        //将搜索内容置为空
        onPressed: () {
          query = "";
          showSuggestions(context);
        },
      )
    ];
  }

  //重写返回图标
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: AnimatedIcon(
            icon: AnimatedIcons.menu_arrow,
            progress: transitionAnimation
        ),
        //关闭上下文，当前页面
        onPressed: () => close(context, ''));
  }

  //重写搜索结果
  @override
  Widget buildResults(BuildContext context) {
    _future = _getSearchResult(query);
    return FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return _buildText('网络请求出错了');
            }
            if (snapshot.hasData && snapshot.data != null) {
              try {
                final List<VideoModel> videoList = snapshot.data! as List<VideoModel>;
                if (videoList.isEmpty) {
                  return const NoData(tip: '没有搜索到视频');
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(4),
                  itemCount: videoList.length,
                  itemBuilder: (context, index) {
                    final video = videoList[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
                          'videoId': video.id,
                        });
                      },
                      child: Container(
                        height: 100,
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
                              child: AspectRatio(
                                aspectRatio: 4 / 3,
                                child: FadeInImage.assetNetwork(
                                  placeholder: 'assets/image/placeholder-l.jpg',
                                  image: video.pic ?? '',
                                  fit: BoxFit.cover,
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
                            const Icon(Icons.play_circle_outline, size: 32, color: Colors.grey,)
                          ],
                        ),
                      ),
                    );
                  }
                );
              } catch (e) {
                return _buildText('数据解析错误');
              }
            } else {
              return _buildText('没有找到视频');
            }
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
//      Column(
//      children: <Widget>[
//        Container(
//          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
//          alignment: Alignment.centerLeft,
//          child: Text(
//              '大家都在搜：',
//              style: TextStyle(
//                  color: Colors.black,
//                  fontSize: 18.0
//              )
//          ),
//        ),
//        Wrap(
//          spacing: 16,
//          alignment: WrapAlignment.start,
//          children: _suggestList.map((str) {
//            return RaisedButton(
//              child: Text(str),
//              onPressed: () {
//                query = str;
//                showResults(context);
//              },
//            );
//          }).toList(),
//        )
//
//      ],
//    );
  }
}
