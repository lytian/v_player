import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:v_player/widgets/chewie/chewie_player.dart';
import 'package:v_player/widgets/chewie/material_progress_bar.dart';
import 'package:v_player/widgets/chewie/utils.dart';
import 'package:video_player/video_player.dart';

class MaterialControls extends StatefulWidget {

  const MaterialControls({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MaterialControlsState();
  }
}

class _MaterialControlsState extends State<MaterialControls> {
  VideoPlayerValue _latestValue;
  double _latestVolume;
  bool _hideStuff = true;
  Timer _hideTimer;
  Timer _initTimer;
  Timer _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;

  final barHeight = 48.0;
  final marginSize = 5.0;

  VideoPlayerController controller;
  ChewieController chewieController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
        context,
        chewieController.videoPlayerController.value.errorDescription,
      )
          : Center(
        child: Icon(
          Icons.error,
          color: Colors.white,
          size: 42,
        ),
      );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _cancelAndRestartTimer(),
        onDoubleTap: () => _playPause(),
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Column(
            children: <Widget>[
              chewieController.showTopBar ? _buildTopBar(context) : Container(),
              _latestValue != null &&
                  !_latestValue.isPlaying &&
                  _latestValue.duration == null ||
                  _latestValue.isBuffering
                  ? const Expanded(
                child: const Center(
                  child: const CircularProgressIndicator(),
                ),
              )
                  : _buildHitArea(),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  void _dispose() {
    controller.removeListener(_updateState);
    _hideTimer?.cancel();
    _initTimer?.cancel();
    _showAfterExpandCollapseTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = chewieController;
    chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  /// 顶部导航条
  AnimatedOpacity _buildTopBar(BuildContext context,) {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight - 6 + (chewieController.isFullScreen ? MediaQuery.of(context).padding.top : 0),
        width: double.infinity,
        padding: EdgeInsets.only(left: marginSize, right: marginSize, top: chewieController.isFullScreen ? MediaQuery.of(context).padding.top : 0),
        color: Colors.black.withOpacity(0.24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            BackButton(
              color: Colors.white,
              onPressed: chewieController.onBack,
            ),
            Expanded(
              flex: 1,
              child: Text(chewieController.title != null && chewieController.isFullScreen ? chewieController.title : '',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
            ),
            chewieController.showDownload ? _buildDownload() : Container()
          ],
        ),
      ),
    );
  }

  /// 底部控制器
  AnimatedOpacity _buildBottomBar(
      BuildContext context,
      ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        color: Colors.black.withOpacity(0.24),
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            chewieController.isLive
                ? Expanded(child: const Text('LIVE'))
                : _buildPosition(iconColor),
            chewieController.isLive ? const SizedBox() : _buildProgressBar(),
            chewieController.allowMuting
                ? _buildMuteButton(controller)
                : Container(),
            chewieController.allowFullScreen
                ? _buildExpandButton()
                : Container(),
          ],
        ),
      ),
    );
  }

  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: EdgeInsets.only(right: 12.0),
          padding: EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen
                  ? Icons.fullscreen_exit
                  : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Expanded _buildHitArea() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else
              _cancelAndRestartTimer();
          } else {
            _playPause();

            setState(() {
              _hideStuff = true;
            });
          }
        },
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: AnimatedOpacity(
              opacity:
              _latestValue != null && !_latestValue.isPlaying && !_dragging
                  ? 1.0
                  : 0.0,
              duration: Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(Icons.play_arrow, size: 32.0, color: Colors.white,),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildMuteButton(
      VideoPlayerController controller,
      ) {
    return GestureDetector(
      onTap: () {
        _cancelAndRestartTimer();

        if (_latestValue.volume == 0) {
          controller.setVolume(_latestVolume ?? 0.5);
        } else {
          _latestVolume = controller.value.volume;
          controller.setVolume(0.0);
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            child: Container(
              height: barHeight,
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
              ),
              child: Icon(
                (_latestValue != null && _latestValue.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
        ),
      ),
    );
  }

  GestureDetector _buildDownload() {
    return GestureDetector(
      onTap: () {
        chewieController.onDownload();
      },
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: EdgeInsets.only(left: 8.0, right: 4.0),
        padding: EdgeInsets.only(
          left: 12.0,
          right: 12.0,
        ),
        child: Icon(
          Icons.file_download,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.white,
        ),
      ),
    );
  }

  void _cancelAndRestartTimer() {
    _hideTimer?.cancel();
    _startHideTimer();

    setState(() {
      _hideStuff = false;
      _displayTapped = true;
    });
  }

  Future<Null> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(Duration(milliseconds: 200), () {
        setState(() {
          _hideStuff = false;
        });
      });
    }
  }

  void _onExpandCollapse() {
    setState(() {
      _hideStuff = true;

      chewieController.toggleFullScreen();
      _showAfterExpandCollapseTimer = Timer(Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    bool isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration(seconds: 0));
          }
          controller.play();
        }
      }
    });
  }

  void _startHideTimer() {
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() {
        _hideStuff = true;
      });
    });
  }

  void _updateState() {
    setState(() {
      _latestValue = controller.value;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: 20.0),
        child: MaterialVideoProgressBar(
            controller,
            onDragStart: () {
              setState(() {
                _dragging = true;
              });

              _hideTimer?.cancel();
            },
            onDragEnd: () {
              setState(() {
                _dragging = false;
              });

              _startHideTimer();
            }
        ),
      ),
    );
  }

  OverlayEntry _tipOverlay;

  void showTooltip(Widget w) {
    hideTooltip();
    _tipOverlay = OverlayEntry(
        builder: (BuildContext context) {
          return IgnorePointer(
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                height: 100.0,
                width: 100.0,
                child: DefaultTextStyle(
                  child: w,
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.white,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }
    );
    Overlay.of(context).insert(_tipOverlay);
  }

  void hideTooltip() {
    _tipOverlay?.remove();
    _tipOverlay = null;
  }

  final int _QUICK_DURATION = 100; // 快速滑动的时间间隔
  double _startPosition = 0; // 滑动的起始位置
  double _dragDistance = 0; // 滑动的距离
  int _startTimeStamp = 0; // 滑动的起始时间，毫秒
  int _dragDuration = 0; // 滑动的间隔时间，毫秒
  bool _leftVerticalDrag; // 是否左边滑动

  void _resetDragParam() {
    _startPosition = 0;
    _dragDuration = 0;
    _startTimeStamp = 0;
    _dragDuration = 0;
  }

  Function wrapHorizontalGesture(Function function) =>
      chewieController.horizontalGesture == true ? function : (DragStartDetails details) {};

  Function wrapVerticalGesture(Function function) =>
      chewieController.verticalGesture == true ? function : (dynamic details) {};

  void _onHorizontalDragStart(DragStartDetails details) {
    if (chewieController.horizontalGesture != true || _latestValue == null) return;

    _startPosition = details.globalPosition.dx;
    _startTimeStamp = details.sourceTimeStamp.inMilliseconds;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (chewieController.horizontalGesture != true || _latestValue == null) return;
    if (_startPosition <= 0 || details == null) return;

    _dragDistance = details.globalPosition.dx - _startPosition;
    _dragDuration = details.sourceTimeStamp.inMilliseconds - _startTimeStamp;
    var f = _dragDistance > 0 ? "+" : "-";
    var offset = (_dragDistance / 10).round().abs();
    if (_dragDuration < _QUICK_DURATION) offset = 5;

    showTooltip(Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          _dragDistance > 0 ? Icons.fast_forward : Icons.fast_rewind,
          color: Colors.white,
          size: 40.0,
        ),
        Text(
          "$f${offset}s",
          textAlign: TextAlign.center,
        ),
      ],
    ));
  }

  void _onHorizontalDragEnd(DragEndDetails details) async  {
    if (chewieController.horizontalGesture != true || _latestValue == null) return;

    int seekMill = _latestValue.position.inMilliseconds;
    if (_dragDuration <= _QUICK_DURATION) {
      // 快速滑动，默认5s
      seekMill += _dragDistance > 0 ? 5000 : -5000;
    } else {
      seekMill += (_dragDistance * 100).toInt();
    }
    // 区间控制
    if (seekMill < 0) {
      seekMill = 0;
    } else if (seekMill > _latestValue.duration.inMilliseconds) {
      seekMill = _latestValue.duration.inMilliseconds;
    }
    controller.seekTo(Duration(milliseconds: seekMill));
    // 延时关闭
    await Future<void>.delayed(Duration(milliseconds: 200));
    hideTooltip();
    _resetDragParam();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (chewieController.verticalGesture != true) return;

    // 判断滑动的位置是在左边还是右边
    RenderBox renderObject = context.findRenderObject() as RenderBox;
    if (renderObject == null) return;
    var bounds = renderObject.paintBounds;
    Offset localOffset = renderObject.globalToLocal(details.globalPosition);
    _leftVerticalDrag  = localOffset.dx / bounds.width <= 0.5;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (chewieController.verticalGesture != true) return;
    if (_leftVerticalDrag == null || details == null) return;

    IconData iconData = Icons.volume_up;
    String text = "";

    if (_leftVerticalDrag == false) {
      // 右边区域，控制音量
      await chewieController.setVolume(_latestValue.volume - details.delta.dy / 200);

      if (_latestValue.volume <= 0) {
        iconData = Icons.volume_mute;
      } else if (_latestValue.volume < 0.5) {
        iconData = Icons.volume_down;
      } else {
        iconData = Icons.volume_up;
      }
      text = (_latestValue.volume * 100).toStringAsFixed(0);
    } else {
      // 左边区域，控制屏幕亮度
      double brightness = await Screen.brightness;
      brightness -= details.delta.dy / 150;

      if (brightness > 1) {
        brightness = 1;
      } else if (brightness < 0) {
        brightness = 0;
      }
      // 设置亮度
      await Screen.setBrightness(brightness);

      if (brightness >= 0.66) {
        iconData = Icons.brightness_high;
      } else if (brightness < 0.66 && brightness > 0.33) {
        iconData = Icons.brightness_medium;
      } else {
        iconData = Icons.brightness_low;
      }
      text = (brightness * 100).toStringAsFixed(0);
    }

    showTooltip(Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          iconData,
          color: Colors.white,
          size: 25.0,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text(text + '%'),
        ),
      ],
    ));
  }

  void _onVerticalDragEnd(DragEndDetails details)  {
    hideTooltip();
    _leftVerticalDrag = null;

    // 快速滑动，可能没清除完成
    Future.delayed(Duration(milliseconds: 1000), () {
      hideTooltip();
    });
  }
}