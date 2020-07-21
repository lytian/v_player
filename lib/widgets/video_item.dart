import 'package:flutter/material.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/router/application.dart';
import 'package:v_player/router/routers.dart';
import 'package:v_player/utils/fluro_convert_util.dart';

/// 横向的
class LandscapeVideoItem extends StatelessWidget {
  VideoModel video;

  LandscapeVideoItem(this.video);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
//        String name = FluroConvertUtils.fluroCnParamsEncode(video.name);
//        Application.router.navigateTo(context, Routers.detailPage + '?id=${video.id}&name=$name');
      },
      child: Card(
        child: Column(
          children: <Widget>[
            AspectRatio(
              aspectRatio: 16 / 9,
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/image/placeholder-l.jpg',
                image: video.pic,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              margin: EdgeInsets.symmetric(vertical: 5),
              child: Text(
                video.name,
                style: TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 竖向的
class PortraitVideoItem extends StatelessWidget {
  VideoModel video;

  PortraitVideoItem(this.video);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
//        String name = FluroConvertUtils.fluroCnParamsEncode(video.name);
//        Application.router.navigateTo(context, Routers.detailPage + '?id=${video.id}&name=$name');
      },
      child: Column(
        children: <Widget>[
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FadeInImage.assetNetwork(
                placeholder: 'assets/image/placeholder-p.jpg',
                image: video.pic,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          ),
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              video.name,
              style: TextStyle(fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
