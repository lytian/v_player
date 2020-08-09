import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:v_player/widgets/chewie/chewie_player.dart';
import 'package:v_player/widgets/chewie/material_controls.dart';
import 'package:video_player/video_player.dart';

class PlayerWithControls extends StatelessWidget {
  PlayerWithControls({Key key, this.aspectRatio}) : super(key: key);

  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final ChewieController chewieController = ChewieController.of(context);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _buildPlayerWithControls(chewieController, context),
        ),
      ),
    );
  }

  Container _buildPlayerWithControls(
      ChewieController chewieController, BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          chewieController.placeholder ?? Container(),
          Center(
            child: AspectRatio(
              aspectRatio: chewieController.videoPlayerController.value.aspectRatio,
              child: VideoPlayer(chewieController.videoPlayerController),
            ),
          ),
          chewieController.overlay ?? Container(),
          _buildControls(context, chewieController),
        ],
      ),
    );
  }

  Widget _buildControls(
    BuildContext context,
    ChewieController chewieController,
  ) {
    return chewieController.showControls
        ? chewieController.customControls != null
            ? chewieController.customControls
            : MaterialControls()
        : Container();
  }
}
