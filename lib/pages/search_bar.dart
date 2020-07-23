import 'package:flutter/material.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/http_utils.dart';
import 'package:v_player/widgets/video_item.dart';

class SearchBarDelegate extends SearchDelegate<String> {
  List<String> _suggestList = [];
  Future<List<VideoModel>> _future;

  SearchBarDelegate({
    String hintText,
  }) : super(
      searchFieldLabel: hintText
  );


  Future<List<VideoModel>> _getSearchResult(str) async {
    if (str == null || str == '') return [];

    return await HttpUtils.getVideoList(keyword: str);
  }

  Widget _buildText(String str) {
    return Container(
      child: Center(
        child: Text(str, style: TextStyle(
            color: Colors.redAccent,
            fontSize: 16
        )),
      ),
    );
  }

  //重写右侧的图标
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
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
        onPressed: () => close(context, null));
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
                List<VideoModel> videoList = snapshot.data;
                if (videoList.length == 0) {
                  return Center(
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
            return Center(
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