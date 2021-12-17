import 'package:flutter/material.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/http_util.dart';
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Expanded(
                          flex: 2,
                          child: SizedBox(),
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
                        const Expanded(
                          flex: 3,
                          child: SizedBox(),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                    itemCount: videoList.length,
                    itemBuilder: (context, index) {
                      return VideoItem(video: videoList[index], type: 1,);
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
