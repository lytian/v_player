import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:v_player/models/video_model.dart';
import 'package:v_player/utils/application.dart';

/// 横向的
class VideoItem extends StatelessWidget {

  const VideoItem({
    Key? key,
    required this.video,
    this.type = 0,
  }): super(key: key);

  final VideoModel video;
  final int type; // 0-竖屏(网格布局)    1-横屏(列表布局)

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pushNamed(Application.videoDetailPage, arguments: {
          'videoId': video.id,
        },);
      },
      child: type == 0 ? _buildPortraitItem() : _buildLandscapeItem(),
    );
  }

  Widget _buildLandscapeItem() {
    return Card(
      child: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
              ),
              child: Stack(
                children: <Widget>[
                  FadeInImage.assetNetwork(
                    placeholder: 'assets/image/placeholder-l.jpg',
                    image: video.pic ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    imageErrorBuilder: (context, _, strace) {
                      return strace == null ? Container() : Container(
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/image/placeholder-l.jpg'),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
                      );
                    },
                  ),
                  if (video.note == null || video.note!.isEmpty) Container() else Positioned(
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
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            margin: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              video.name ?? '',
              style: const TextStyle(fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitItem() {
    return Column(
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Stack(
              children: <Widget>[
                FadeInImage.assetNetwork(
                  placeholder: 'assets/image/placeholder-p.jpg',
                  image: video.pic ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  imageErrorBuilder: (context, _, strace) {
                    return strace == null ? Container() : Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/image/placeholder-p.jpg'),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text('图片加载失败', style: TextStyle(color: Colors.redAccent),),
                    );
                  },
                ),
                if (video.note == null || video.note!.isEmpty) Container() else Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(125),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(5),
                      ),
                    ),
                    child: Text(video.note!, overflow: TextOverflow.ellipsis, style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            video.name ?? '',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
