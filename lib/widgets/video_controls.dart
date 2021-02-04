import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:screen/screen.dart';
import 'package:video_player/video_player.dart';

import 'material_progress_bar.dart';

class VideoControls extends MaterialControls {
  const VideoControls({
    Key key,
    this.title,
    this.defaultShowTitle = false,
    this.actions,
    this.horizontalGesture = true,
    this.verticalGesture = true,
  }) : super(key: key);

  /// 视频标题
  final String title;

  /// 是否显示头部
  final bool defaultShowTitle;

  /// 扩展操作
  final Widget actions;

  /// 是否打开水平方向手势
  final bool horizontalGesture ;

  /// 是否打开垂直方向手势
  final bool verticalGesture;

  @override
  State<StatefulWidget> createState() {
    return _VideoPlayerControlsState();
  }
}

class _VideoPlayerControlsState extends State<VideoControls>
    with SingleTickerProviderStateMixin {
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
  AnimationController playPauseIconAnimationController;

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder != null
          ? chewieController.errorBuilder(
        context,
        chewieController.videoPlayerController.value.errorDescription,
      )
          : const Center(
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
              _buildTopBar(context),
              (_latestValue != null &&
                  !_latestValue.isPlaying &&
                  _latestValue.duration == null ||
                  _latestValue.isBuffering)
                ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
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

    playPauseIconAnimationController ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 400),
    );

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  /// 顶部导航条
  AnimatedOpacity _buildTopBar(BuildContext context,) {
    String title = '';
    if (chewieController.isFullScreen || widget.defaultShowTitle) {
      title = widget.title ?? '';
    }
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: barHeight - 8 + (chewieController.isFullScreen || widget.defaultShowTitle ? MediaQuery.of(context).padding.top : 0),
        padding: EdgeInsets.only(left: marginSize, right: marginSize, top: chewieController.isFullScreen || widget.defaultShowTitle ? MediaQuery.of(context).padding.top : 0),
        color: Colors.black.withOpacity(0.24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            BackButton(
              color: Colors.white,
            ),
            Expanded(
                flex: 1,
                child: Text(title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                )
            ),
            widget.actions ?? Container()
          ],
        ),
      ),
    );
  }

  AnimatedOpacity _buildBottomBar(
      BuildContext context,
      ) {
    final iconColor = Theme.of(context).textTheme.button.color;

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight,
        // color: Theme.of(context).dialogBackgroundColor,
        color: Colors.black.withOpacity(0.24),
        child: Row(
          children: <Widget>[
            _buildPlayPause(controller),
            if (chewieController.isLive)
              const Expanded(child: Text('LIVE'))
            else
              _buildPosition(iconColor),
            if (chewieController.isLive)
              const SizedBox()
            else
              _buildProgressBar(),
            if (chewieController.allowPlaybackSpeedChanging)
              _buildSpeedButton(controller),
            if (chewieController.allowMuting) _buildMuteButton(controller),
            if (chewieController.allowFullScreen) _buildExpandButton(),
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
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          margin: const EdgeInsets.only(right: 12.0),
          padding: const EdgeInsets.only(
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
    final bool isFinished = _latestValue.position >= _latestValue.duration;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_latestValue != null && _latestValue.isPlaying) {
            if (_displayTapped) {
              setState(() {
                _hideStuff = true;
              });
            } else {
              _cancelAndRestartTimer();
            }
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
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(48.0),
                  ),
                  child: IconButton(
                    icon: isFinished
                        ? const Icon(Icons.replay, size: 32.0)
                        : AnimatedIcon(
                      icon: AnimatedIcons.play_pause,
                      progress: playPauseIconAnimationController,
                      size: 32.0,
                    ),
                    onPressed: () {
                      _playPause();
                    }
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedButton(
      VideoPlayerController controller,
      ) {
    return GestureDetector(
      onTap: () async {
        _hideTimer?.cancel();

        final chosenSpeed = await showModalBottomSheet<double>(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          builder: (context) => _PlaybackSpeedDialog(
            speeds: chewieController.playbackSpeeds,
            selected: _latestValue.playbackSpeed,
          ),
        );

        if (chosenSpeed != null) {
          controller.setPlaybackSpeed(chosenSpeed);
        }

        if (_latestValue.isPlaying) {
          _startHideTimer();
        }
      },
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
              left: 8.0,
              right: 8.0,
            ),
            child: const Icon(Icons.speed, color: Colors.white,),
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
        duration: const Duration(milliseconds: 300),
        child: ClipRect(
          child: Container(
            height: barHeight,
            padding: const EdgeInsets.only(
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
    );
  }

  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        margin: const EdgeInsets.only(left: 8.0, right: 4.0),
        padding: const EdgeInsets.only(
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

  Widget _buildPosition(Color iconColor) {
    final position = _latestValue != null && _latestValue.position != null
        ? _latestValue.position
        : Duration.zero;
    final duration = _latestValue != null && _latestValue.duration != null
        ? _latestValue.duration
        : Duration.zero;

    return Padding(
      padding: const EdgeInsets.only(right: 24.0),
      child: Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: const TextStyle(
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

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if ((controller.value != null && controller.value.isPlaying) ||
        chewieController.autoPlay) {
      _startHideTimer();
    }

    if (chewieController.showControlsOnInitialize) {
      _initTimer = Timer(const Duration(milliseconds: 200), () {
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
      _showAfterExpandCollapseTimer =
          Timer(const Duration(milliseconds: 300), () {
            setState(() {
              _cancelAndRestartTimer();
            });
          });
    });
  }

  void _playPause() {
    bool isFinished;
    if (_latestValue.duration != null) {
      isFinished = _latestValue.position >= _latestValue.duration;
    } else {
      isFinished = false;
    }

    setState(() {
      if (controller.value.isPlaying) {
        playPauseIconAnimationController.reverse();
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.initialized) {
          controller.initialize().then((_) {
            controller.play();
            playPauseIconAnimationController.forward();
          });
        } else {
          if (isFinished) {
            controller.seekTo(const Duration());
          }
          playPauseIconAnimationController.forward();
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
        padding: const EdgeInsets.only(right: 20.0),
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
          },
          colors: chewieController.materialProgressColors ??
              ChewieProgressColors(
                  playedColor: Theme.of(context).accentColor,
                  handleColor: Theme.of(context).accentColor,
                  bufferedColor: Theme.of(context).backgroundColor,
                  backgroundColor: Theme.of(context).disabledColor),
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

  final int _quickDuration = 100; // 快速滑动的时间间隔
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
      widget.horizontalGesture == true ? function : (DragStartDetails details) {};

  Function wrapVerticalGesture(Function function) =>
      widget.verticalGesture == true ? function : (dynamic details) {};

  void _onHorizontalDragStart(DragStartDetails details) {
    if (widget.horizontalGesture != true || _latestValue == null) return;

    _startPosition = details.globalPosition.dx;
    _startTimeStamp = details.sourceTimeStamp.inMilliseconds;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.horizontalGesture != true || _latestValue == null) return;
    if (_startPosition <= 0 || details == null) return;

    _dragDistance = details.globalPosition.dx - _startPosition;
    _dragDuration = details.sourceTimeStamp.inMilliseconds - _startTimeStamp;
    var f = _dragDistance > 0 ? "+" : "-";
    var offset = (_dragDistance / 10).round().abs();
    if (_dragDuration < _quickDuration) offset = 5;

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
    if (widget.horizontalGesture != true || _latestValue == null) return;

    int seekMill = _latestValue.position.inMilliseconds;
    if (_dragDuration <= _quickDuration) {
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
    if (widget.verticalGesture != true) return;

    // 判断滑动的位置是在左边还是右边
    RenderBox renderObject = context.findRenderObject() as RenderBox;
    if (renderObject == null) return;
    var bounds = renderObject.paintBounds;
    Offset localOffset = renderObject.globalToLocal(details.globalPosition);
    _leftVerticalDrag  = localOffset.dx / bounds.width <= 0.5;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) async {
    if (widget.verticalGesture != true) return;
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

  String formatDuration(Duration position) {
    final ms = position.inMilliseconds;

    int seconds = ms ~/ 1000;
    final int hours = seconds ~/ 3600;
    seconds = seconds % 3600;
    final minutes = seconds ~/ 60;
    seconds = seconds % 60;

    final hoursString = hours >= 10
        ? '$hours'
        : hours == 0
        ? '00'
        : '0$hours';

    final minutesString = minutes >= 10
        ? '$minutes'
        : minutes == 0
        ? '00'
        : '0$minutes';

    final secondsString = seconds >= 10
        ? '$seconds'
        : seconds == 0
        ? '00'
        : '0$seconds';

    final formattedTime =
        '${hoursString == '00' ? '' : '$hoursString:'}$minutesString:$secondsString';

    return formattedTime;
  }
}

class _PlaybackSpeedDialog extends StatelessWidget {
  const _PlaybackSpeedDialog({
    Key key,
    @required List<double> speeds,
    @required double selected,
  })  : _speeds = speeds,
        _selected = selected,
        super(key: key);

  final List<double> _speeds;
  final double _selected;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = Theme.of(context).primaryColor;

    return ListView.builder(
      shrinkWrap: true,
      physics: const ScrollPhysics(),
      itemBuilder: (context, index) {
        final _speed = _speeds[index];
        return ListTile(
          dense: true,
          title: Row(
            children: [
              if (_speed == _selected)
                Icon(
                  Icons.check,
                  size: 20.0,
                  color: selectedColor,
                )
              else
                Container(width: 20.0),
              const SizedBox(width: 16.0),
              Text(_speed.toString()),
            ],
          ),
          selected: _speed == _selected,
          onTap: () {
            Navigator.of(context).pop(_speed);
          },
        );
      },
      itemCount: _speeds.length,
    );
  }
}
