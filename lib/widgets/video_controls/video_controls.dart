import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screen_wake/flutter_screen_wake.dart';
import 'package:video_player/video_player.dart';
import 'package:volume_controller/volume_controller.dart';

import 'animated_play_pause.dart';
import 'center_play_button.dart';
import 'progress_bar.dart';
import 'utils.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({
    Key? key,
    this.title,
    this.speedList = const [],
    this.actions,
    this.alwaysShowTitle = false,
    this.horizontalGesture = true,
    this.verticalGesture = true,
  }) : super(key: key);

  /// 视频标题
  final String? title;

  /// 总是显示标题
  final bool alwaysShowTitle;

  /// 播放速率列表
  final List<double> speedList;

  /// 扩展操作
  final Widget? actions;

  /// 是否打开水平方向手势
  final bool horizontalGesture ;

  /// 是否打开垂直方向手势
  final bool verticalGesture;

  @override
  _VideoControlsState createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  final VolumeController _volumeController = VolumeController();
  late VideoPlayerValue _latestValue;
  double? _latestVolume;
  bool _hideStuff = true;
  Timer? _hideTimer;
  Timer? _initTimer;
  Timer? _showAfterExpandCollapseTimer;
  bool _dragging = false;
  bool _displayTapped = false;
  double _speed = 1.0;
  bool _lockStuff = false;
  bool _hideLockStuff = true;
  bool _hideSpeedStuff = true;
  Timer? _hideLockTimer;

  final barHeight = 48.0;

  late VideoPlayerController controller;
  ChewieController? _chewieController;

  // We know that _chewieController is set in didChangeDependencies
  ChewieController get chewieController => _chewieController!;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_latestValue.hasError) {
      return chewieController.errorBuilder?.call(
        context,
        chewieController.videoPlayerController.value.errorDescription!,
      ) ??
          const Center(
            child: Icon(
              Icons.error,
              color: Colors.white,
              size: 42,
            ),
          );
    }

    // 是否锁定
    if (_lockStuff == true) {
      return WillPopScope(
       onWillPop: () {
         if (_lockStuff) {
           setState(() {
             _hideLockStuff = false;
           });
           return Future.value(false);
         }
         return Future.value(true);
       },
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _cancelAndRestartLockTimer,
              child: Container(),
            ),
            AnimatedOpacity(
              opacity: _hideLockStuff ? 0.0 : 1,
              duration: const Duration(milliseconds: 300),
              child: _buildLockBtn(),
            ),
          ],
        ),
      );
    }

    return MouseRegion(
      onHover: (_) {
        _cancelAndRestartTimer();
      },
      child: GestureDetector(
        onTap: () => _cancelAndRestartTimer(),
        child: AbsorbPointer(
          absorbing: _hideStuff,
          child: Stack(
            children: [
              if (_latestValue.isBuffering)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else
                _buildHitArea(),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(context),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(context),
              ),
              // 锁按钮
              if (widget.alwaysShowTitle || chewieController.isFullScreen)
                _buildLockBtn(),
              // 倍数选择
              if (!_hideSpeedStuff)
                _buildSpeedList(),
              // 顶部显示 (快进时间、音量、亮度)
              if (_isHorizontalTouching || _isVerticalTouching)
                Positioned(
                  top: barHeight + 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 显示左右滑动快进时间的块
                      if (_isHorizontalTouching)
                        _buildDragProgressTime(),
                      // 显示上下滑动音量亮度
                      if (_isVerticalTouching)
                        _buildDragVolumeAndBrightness(),
                    ],
                  ),
                ),
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
    _hideLockTimer?.cancel();
  }

  @override
  void didChangeDependencies() {
    final _oldController = _chewieController;
    _chewieController = ChewieController.of(context);
    controller = chewieController.videoPlayerController;

    if (_oldController != chewieController) {
      _dispose();
      _initialize();
    }

    super.didChangeDependencies();
  }

  bool get fullscreen {
    return widget.alwaysShowTitle || chewieController.isFullScreen;
  }

  /// 顶部导航条
  AnimatedOpacity _buildTopBar(BuildContext context,) {
    String title = '';
    if (fullscreen) {
      title = widget.title ?? '';
    }
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        width: double.infinity,
        height: barHeight - 8 + (fullscreen ? 6.0 : 0),
        padding: EdgeInsets.only(
          left: 6.0,
          right: 6.0,
          top: fullscreen ? 6.0 : 0,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black38,
              Colors.black26,
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          children: <Widget>[
            const BackButton(
              color: Colors.white,
            ),
            Expanded(
              child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14.0),
              ),
            ),
            widget.actions ?? Container()
          ],
        ),
      ),
    );
  }

  /// 底部操作栏
  AnimatedOpacity _buildBottomBar(BuildContext context,) {
    final position = _latestValue.position;
    final duration = _latestValue.duration;

    Widget bottomWidget;
    if (fullscreen) {
      // 全屏
      bottomWidget = SafeArea(
        bottom: fullscreen,
        child: Container(
          padding: EdgeInsets.only(
            right: 20,
            left: 20,
            bottom: fullscreen ? 6.0 : 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!chewieController.isLive)
                Expanded(child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Text(formatDuration(position),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    _buildProgressBar(),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: Text(formatDuration(duration),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),),
              Flexible(
                child: Row(
                  children: <Widget>[
                    _buildPlayPause(controller),
                    _buildMuteButton(controller),
                    if (chewieController.isLive) const Expanded(child: Text('LIVE')),
                    const Spacer(),
                    _buildSpeedButton(),
                    if (chewieController.allowFullScreen) _buildExpandButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      bottomWidget = Row(
        children: [
          _buildPlayPause(controller),
          if (!chewieController.isLive)
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Text(formatDuration(position),
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
            ),
          if (chewieController.isLive)
            const Expanded(child: Text('LIVE'))
          else
            _buildProgressBar(),
          if (!chewieController.isLive)
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Text(formatDuration(duration),
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
            ),
          if (chewieController.allowFullScreen) _buildExpandButton(),
        ],
      );
    }

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        height: barHeight + (fullscreen ? 18.0 : 0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black38,
              Colors.black26,
              Colors.transparent,
            ],
          ),
        ),
        child: bottomWidget,
      ),
    );
  }

  /// 倍速播放按钮
  GestureDetector _buildSpeedButton() {
    String str = '倍速';
    if (_speed != 1.0) {
      str += ' ${_speed}X';
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _hideSpeedStuff = !_hideSpeedStuff;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 92.0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed,color: Colors.white,),
            const SizedBox(width: 4.0,),
            Text(str,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 全屏切换按钮
  GestureDetector _buildExpandButton() {
    return GestureDetector(
      onTap: _onExpandCollapse,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight + (chewieController.isFullScreen ? 15.0 : 0),
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Center(
            child: Icon(
              chewieController.isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 锁屏按钮
  Widget _buildLockBtn() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1,
        duration: const Duration(milliseconds: 300),
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: GestureDetector(
            onTap: () {
              _lockStuff = !_lockStuff;
              if (_lockStuff) {
                // 锁定
                _hideLockStuff = false;
                _hideTimer?.cancel();
                _startHideLockTimer();
              } else {
                // 解锁
                _cancelAndRestartTimer();
              }
              setState(() {});
            },
            child: Icon(_lockStuff ? Icons.lock_outline : Icons.lock_open, color: Colors.white, size: 25,),
          ),
        ),
      ),
    );
  }

  /// 中间区域
  Widget _buildHitArea() {
    final bool isFinished = _latestValue.position >= _latestValue.duration;
    final bool showPlayButton = !_dragging && !_hideStuff && !_isHorizontalTouching && !_isVerticalTouching;

    return Positioned(
      left: 0,
      top: barHeight - 8 +(fullscreen ? 6.0 : 0),
      right: 0,
      bottom: barHeight + (fullscreen ? 18.0 : 0),
      child: GestureDetector(
        onTap: () {
          if (_latestValue.isPlaying) {
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
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: chewieController.isFullScreen ? CenterPlayButton(
          backgroundColor: Colors.black54,
          iconColor: Colors.white,
          isFinished: isFinished,
          isPlaying: controller.value.isPlaying,
          show: showPlayButton,
          onPressed: _playPause,
        ) : Container(
          color: Colors.transparent,
        ),
      ),
    );
  }

  /// 静音按钮
  GestureDetector _buildMuteButton(VideoPlayerController controller,) {
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
              right: 8.0,
              left: 4.0,
            ),
            child: Icon(
              _latestValue.volume > 0 ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  /// 播放/暂停按钮
  GestureDetector _buildPlayPause(VideoPlayerController controller) {
    return GestureDetector(
      onTap: _playPause,
      child: Container(
        height: barHeight,
        color: Colors.transparent,
        padding: const EdgeInsets.only(
          left: 4.0,
          right: 8.0,
        ),
        child: AnimatedPlayPause(
          playing: controller.value.isPlaying,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 倍数列表框
  Widget _buildSpeedList() {
    double speedMargin = 28.0;
    if (chewieController.allowFullScreen) {
      speedMargin += 40.0;
    }
    return Positioned(
      right: speedMargin,
      bottom: barHeight + 12.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(5),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: chewieController.playbackSpeeds.reversed.map((val) => Ink(
            child: InkWell(
              onTap: () async {
                if (_speed == val) return;
                await controller.setPlaybackSpeed(val);
                setState(() {
                  _speed = val;
                  _hideSpeedStuff = true;
                });
              },
              child: Container(
                alignment: Alignment.center,
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white54, width: 0.5),
                  ),
                ),
                child: Text("${val}X",
                  style: TextStyle(
                    color: _speed == val ? Colors.blue : Colors.white,
                    fontSize: 14.0,
                  ),
                ),
              ),
            ),
          ),).toList(),
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
      if (_hideStuff == true) {
        _hideSpeedStuff = true;
      }
    });
  }

  Future<void> _initialize() async {
    controller.addListener(_updateState);

    _updateState();

    if (controller.value.isPlaying || chewieController.autoPlay) {
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
      _showAfterExpandCollapseTimer = Timer(const Duration(milliseconds: 300), () {
        setState(() {
          _cancelAndRestartTimer();
        });
      });
    });
  }

  void _playPause() {
    final isFinished = _latestValue.position >= _latestValue.duration;

    setState(() {
      if (controller.value.isPlaying) {
        _hideStuff = false;
        _hideTimer?.cancel();
        controller.pause();
      } else {
        _cancelAndRestartTimer();

        if (!controller.value.isInitialized) {
          controller.initialize().then((_) {
            controller.play();
          });
        } else {
          if (isFinished) {
            controller.seekTo(Duration.zero);
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
        _hideSpeedStuff = true;
      });
    });
  }

  void _updateState() {
    if (!mounted) return;
    setState(() {
      _latestValue = controller.value;
    });
  }

  /// 开启隐藏锁定定时器
  void _startHideLockTimer() {
    _hideLockTimer?.cancel();
    _hideLockTimer = Timer(const Duration(seconds: 4), () {
      setState(() {
        _hideLockStuff = true;
      });
    });
  }

  /// 取消并重启隐藏锁定定时器
  void _cancelAndRestartLockTimer() {
    _hideLockTimer?.cancel();
    _startHideLockTimer();
    // if (_hideLockStuff == true) {
    //   _startHideTimer();
    // }

    setState(() {
      _hideLockStuff = !_hideLockStuff;
    });
  }

  Widget _buildProgressBar() {
    return Expanded(
      child: VideoProgressBar(
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
            playedColor: Theme.of(context).colorScheme.secondary,
            handleColor: Theme.of(context).colorScheme.secondary,
            bufferedColor: Theme.of(context).backgroundColor.withOpacity(0.5),
            backgroundColor: Theme.of(context).disabledColor.withOpacity(.5),
          ),
      ),
    );
  }

  /// 滑动进度时间显示
  Widget _buildDragProgressTime() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
        color: Color.fromRGBO(0, 0, 0, 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10),
        child: Text(
          '${formatDuration(_dragPos)} / ${formatDuration(_latestValue.duration)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14.0,
          ),
        ),
      ),
    );
  }
  
  /// 显示垂直亮度，音量
  Widget _buildDragVolumeAndBrightness() {
    IconData iconData;
    // 判断当前值范围，显示的图标
    if (_updateDragVarVal! <= 0) {
      iconData = !_isDragVerLeft ? Icons.volume_off : Icons.brightness_low;
    } else if (_updateDragVarVal! < 0.25) {
      iconData = !_isDragVerLeft ? Icons.volume_mute : Icons.brightness_medium;
    } else if (_updateDragVarVal! < 0.75) {
      iconData = !_isDragVerLeft ? Icons.volume_down : Icons.brightness_medium;
    } else {
      iconData = !_isDragVerLeft ? Icons.volume_up : Icons.brightness_high;
    }
    // 显示，亮度 || 音量
    return Card(
      color: const Color.fromRGBO(0, 0, 0, 0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              iconData,
              color: Colors.white,
            ),
            Container(
              width: 100.0,
              height: 3.0,
              margin: const EdgeInsets.only(left: 8.0),
              child: LinearProgressIndicator(
                value: _updateDragVarVal,
                backgroundColor: Colors.white54,
                valueColor: const AlwaysStoppedAnimation(Colors.lightBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Duration _dragPos = Duration.zero; // 滑动后的时间值
  bool _isDragVerLeft = false;
  late double _updatePrevDx;
  late double _updatePrevDy;
  late int _updatePosX;

  double? _updateDragVarVal;
  bool _isVerticalTouching = false;
  bool _isHorizontalTouching = false;

  // 水平滑动
  void _onHorizontalDragStart(DragStartDetails details) {
    if (widget.horizontalGesture != true) return;

    setState(() {
      _updatePrevDx = details.globalPosition.dx;
      _updatePosX = _latestValue.position.inSeconds;
    });
  }
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.horizontalGesture != true) return;

    final double curDragDx = details.globalPosition.dx;
    // 确定当前是前进或者后退
    final int cdx = curDragDx.toInt();
    final int pdx = _updatePrevDx.toInt();
    final bool isBefore = cdx > pdx;
    // + -, 不满足, 左右滑动合法滑动值，> 4
    if (isBefore && cdx - pdx < 3 || !isBefore && pdx - cdx < 3) return;

    int dragRange = isBefore ? _updatePosX + 1 : _updatePosX - 1;
    final int lastSecond = _latestValue.duration.inSeconds;
    if (dragRange >= lastSecond) {
      // 是否溢出 最大
      dragRange = lastSecond;
    } else if (dragRange <= 0) {
      // 是否溢出 最小
      dragRange = 0;
    }
    setState(() {
      _hideStuff = false;
      _isHorizontalTouching = true;
      // 更新下上一次存的滑动位置
      _updatePrevDx = curDragDx;
      // 更新时间
      _updatePosX = dragRange;
      _dragPos = Duration(seconds: _updatePosX);
    });
  }
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.horizontalGesture != true) return;

    chewieController.seekTo(_dragPos);
    setState(() {
      _isHorizontalTouching = false;
      _hideStuff = true;
    });
  }

  // 垂直滑动
  Future<void> _onVerticalDragStart(DragStartDetails details) async {
    if (widget.verticalGesture != true) return;

    final RenderBox renderObject = context.findRenderObject()! as RenderBox;
    final bounds = renderObject.paintBounds;
    final Offset localOffset = renderObject.globalToLocal(details.globalPosition);
    _isDragVerLeft  = localOffset.dx / bounds.width <= 0.5;
    _updatePrevDy = details.globalPosition.dy;

    // 大于 右边 音量 ， 小于 左边 亮度
    if (!_isDragVerLeft) {
      // 音量
      await _volumeController.getVolume().then((double v) {
        _isVerticalTouching = true;
        setState(() {
          _updateDragVarVal = v;
        });
      });
    } else {
      // 亮度
      await FlutterScreenWake.brightness.then((double v) {
        _isVerticalTouching = true;
        setState(() {
          _updateDragVarVal = v;
        });
      });
    }
  }
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (widget.verticalGesture != true) return;
    if (!_isVerticalTouching) return;
    final double curDragDy = details.globalPosition.dy;
    // 确定当前是前进或者后退
    final int cdy = curDragDy.toInt();
    final int pdy = _updatePrevDy.toInt();
    final bool isBefore = cdy < pdy;
    // + -, 不满足, 上下滑动合法滑动值，> 3
    if (isBefore && pdy - cdy < 10 || !isBefore && cdy - pdy < 10) return;
    // 区间
    double dragRange = isBefore ? _updateDragVarVal! + 0.1 : _updateDragVarVal! - 0.1;
    // 是否溢出
    if (dragRange > 1) {
      dragRange = 1.0;
    }
    if (dragRange < 0) {
      dragRange = 0.0;
    }
    setState(() {
      _updatePrevDy = curDragDy;
      _isVerticalTouching = true;
      _updateDragVarVal = dragRange;
      // 音量
      if (!_isDragVerLeft) {
        _volumeController.setVolume(dragRange, showSystemUI: false);
      } else {
        FlutterScreenWake.setBrightness(dragRange);
      }
    });
  }
  void _onVerticalDragEnd(DragEndDetails details) {
    if (widget.verticalGesture != true) return;

    setState(() {
      _isVerticalTouching = false;
    });
  }

}
