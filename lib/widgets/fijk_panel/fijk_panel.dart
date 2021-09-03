import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:v_player/widgets/fijk_panel/custom_slider.dart';

import 'animated_play_pause.dart';
import 'center_play_button.dart';

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class FijkPanel extends StatefulWidget {
  /// 播放器 FijkPlayer对象
  final FijkPlayer player;
  /// 实际显示大小
  final Size viewSize;
  /// 视频显示的相对位置
  final Rect texturePos;
  /// 页面上下文
  final BuildContext? pageContext;
  /// 允许静音
  final bool allowMute;
  /// 允许全屏
  final bool allowFullScreen;
  /// 是否显示顶部内容
  final bool showTopCon;
  /// 视频标题
  final String playerTitle;
  /// 播放速率列表
  final List<double> speedList;
  /// 顶部操作栏
  final Widget? actionWidget;
  /// 选集Widget
  final Widget Function(BuildContext, Function)? playlistBuilder;
  /// 重新播放
  final VoidCallback? onReplay;

  FijkPanel({
    required this.player,
    required this.viewSize,
    required this.texturePos,
    this.pageContext,
    this.allowMute = false,
    this.allowFullScreen = true,
    this.showTopCon = true,
    this.playerTitle = "",
    this.speedList = const [0.5, 1, 1.25, 1.5, 2],
    this.actionWidget,
    this.playlistBuilder,
    this.onReplay,
  });

  @override
  _FijkPanelState createState() => _FijkPanelState();
}

class _FijkPanelState extends State<FijkPanel> with TickerProviderStateMixin, WidgetsBindingObserver {
  FijkPlayer get player => widget.player;

  Duration _duration = Duration();
  Duration _currentPos = Duration();
  Duration _bufferPos = Duration();
  Duration _dragPos = Duration(); // 滑动后值

  bool _isTouch = false;
  bool _playing = false;
  bool _prepared = false;
  bool _drawerState = false;
  bool _isMute = false;
  String? _exception;

  bool _buffering = false;
  double _seekPos = -1.0;
  double? _latestVolume;

  double? _updatePrevDx;
  double? _updatePrevDy;
  int? _updatePosX;
  bool? _isDragVerLeft;
  double? _updateDragVarVal;
  bool _varTouchInitSuc = false;

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;
  StreamSubscription? _bufferingSubs;

  Timer? _hideTimer;
  Timer? _hideLockTimer;
  bool _hideStuff = true;
  bool _lockStuff = false;
  bool _hideLockStuff = true;
  bool _hideSpeedStu = true;

  final barHeight = 48.0;
  double _speed = 1.0;

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween(
      begin: Offset(1, 0),
      end: Offset.zero,
    ).animate(_animationController);

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _exception = player.value.exception.message;
    _buffering = player.isBuffering;

    player.addListener(_playerValueChanged);
    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
      });
    });
    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });
    _bufferingSubs = player.onBufferStateUpdate.listen((v) {
      setState(() {
        _buffering = v;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_playing == false) {
          player.start();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        if (_playing == true) {
          player.pause();
        }
        break;
      default:
        break;
    }
  }

  // ++++++++++++++++++++水平滑动+++++++++++++++++++++++
  _onHorizontalDragStart(details) {
    setState(() {
      _updatePrevDx = details.globalPosition.dx;
      _updatePosX = _currentPos.inSeconds;
    });
  }
  _onHorizontalDragUpdate(details) {
    double curDragDx = details.globalPosition.dx;
    // 确定当前是前进或者后退
    int cdx = curDragDx.toInt();
    int pdx = _updatePrevDx!.toInt();
    bool isBefore = cdx > pdx;
    // + -, 不满足, 左右滑动合法滑动值，> 4
    if (isBefore && cdx - pdx < 3 || !isBefore && pdx - cdx < 3) return null;

    int dragRange = isBefore ? _updatePosX! + 1 : _updatePosX! - 1;
    // 是否溢出 最大
    int lastSecond = _duration.inSeconds;
    if (dragRange >= _duration.inSeconds) {
      dragRange = lastSecond;
    }
    // 是否溢出 最小
    if (dragRange <= 0) {
      dragRange = 0;
    }
    this.setState(() {
      _hideStuff = false;
      _isTouch = true;
      // 更新下上一次存的滑动位置
      _updatePrevDx = curDragDx;
      // 更新时间
      _updatePosX = dragRange.toInt();
      _dragPos = Duration(seconds: _updatePosX!.toInt());
    });
  }
  _onHorizontalDragEnd(details) {
    player.seekTo(_dragPos.inMilliseconds);
    this.setState(() {
      _isTouch = false;
      _hideStuff = true;
      _currentPos = _dragPos;
    });
  }

  // +++++++++++++++++++垂直滑动++++++++++++++++++++++++
  _onVerticalDragStart(details) async {
    double clientW = widget.viewSize.width;
    double curTouchPosX = details.globalPosition.dx;

    setState(() {
      // 更新位置
      _updatePrevDy = details.globalPosition.dy;
      // 是否左边
      _isDragVerLeft = (curTouchPosX > (clientW / 2)) ? false : true;
    });
    // 大于 右边 音量 ， 小于 左边 亮度
    if (!_isDragVerLeft!) {
      // 音量
      await FijkVolume.getVol().then((double v) {
        _varTouchInitSuc = true;
        setState(() {
          _updateDragVarVal = v;
        });
      });
    } else {
      // 亮度
      await FijkPlugin.screenBrightness().then((double v) {
        _varTouchInitSuc = true;
        setState(() {
          _updateDragVarVal = v;
        });
      });
    }
  }
  _onVerticalDragUpdate(details) {
    if (!_varTouchInitSuc) return null;
    double curDragDy = details.globalPosition.dy;
    // 确定当前是前进或者后退
    int cdy = curDragDy.toInt();
    int pdy = _updatePrevDy!.toInt();
    bool isBefore = cdy < pdy;
    // + -, 不满足, 上下滑动合法滑动值，> 3
    if (isBefore && pdy - cdy < 10 || !isBefore && cdy - pdy < 10) return null;
    // 区间
    double dragRange =
    isBefore ? _updateDragVarVal! + 0.1 : _updateDragVarVal! - 0.1;
    // 是否溢出
    if (dragRange > 1) {
      dragRange = 1.0;
    }
    if (dragRange < 0) {
      dragRange = 0.0;
    }
    setState(() {
      _updatePrevDy = curDragDy;
      _varTouchInitSuc = true;
      _updateDragVarVal = dragRange;
      // 音量
      if (!_isDragVerLeft!) {
        FijkVolume.setVol(dragRange);
      } else {
        FijkPlugin.setScreenBrightness(dragRange);
      }
    });
  }
  _onVerticalDragEnd(details) {
    setState(() {
      _varTouchInitSuc = false;
    });
  }

  /// 播放器变化监听
  void _playerValueChanged() async {
    // await player.stop();
    FijkValue value = player.value;
    if (value.duration != _duration) {
      setState(() {
        _duration = value.duration;
      });
    }
    bool playing = (value.state == FijkState.started);
    bool prepared = value.prepared;
    String? exception = value.exception.message;
    // 状态不一致，修改
    if (playing != _playing ||
        prepared != _prepared ||
        exception != _exception) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
        _exception = exception;
      });
    }
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    _hideTimer?.cancel();
    _hideLockTimer?.cancel();

    player.removeListener(_playerValueChanged);
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    _bufferingSubs?.cancel();
    _animationController.dispose();
  }

  /// 开启隐藏操作栏定时器
  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideStuff = true;
        _hideSpeedStu = true;
      });
    });
  }

  /// 开启隐藏锁定定时器
  void _startHideLockTimer() {
    _hideLockTimer?.cancel();
    _hideLockTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideLockStuff = true;
      });
    });
  }

  /// 取消并重启隐藏操作栏定时器
  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }

    setState(() {
      _hideStuff = !_hideStuff;
      if (_hideStuff == true) {
        _hideSpeedStu = true;
      }
    });
  }

  /// 取消并重启隐藏锁定定时器
  void _cancelAndRestartLockTimer() {
    if (_hideLockStuff == true) {
      _startHideTimer();
    }

    setState(() {
      _hideLockStuff = !_hideLockStuff;
    });
  }

  void _closePlaylist() async {
    await _animationController.reverse();
    setState(() {
      _drawerState = false;
    });
  }

  void _openPlaylist() {
    setState(() {
      _drawerState = true;
    });
    _animationController.forward();
  }

  /// 播放/暂停 按钮
  GestureDetector _buildPlayStateBtn() {
    return GestureDetector(
      onTap: _playOrPause,
      child: Container(
        height: double.infinity,
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: AnimatedPlayPause(
          playing: _playing,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 静音按钮
  GestureDetector _buildMuteBtn() {
    return GestureDetector(
      onTap: () async {
        double vol = await FijkVolume.getVol();
        if (vol <= 0) {
          FijkVolume.setVol(_latestVolume ?? 0.5);
        } else {
          _latestVolume = vol;
          FijkVolume.mute();
        }
        setState(() {
          _isMute = vol > 0;
        });
      },
      child: Container(
        height: barHeight,
        padding: const EdgeInsets.only(
          right: 15.0,
        ),
        child: Icon(
          _isMute ? Icons.volume_off : Icons.volume_up,
          color: Colors.white,
        ),
      ),
    );
  }

  /// 全屏播放按钮
  GestureDetector _buildExpandBtn() {
    return GestureDetector(
      onTap: () {
        if (player.value.fullScreen) {
          player.exitFullScreen();
        } else {
          player.enterFullScreen();
          // 延时加载
          if (!_animationController.isDismissed) {
            _animationController.forward();
          }
        }
      },
      child: Container(
        height: double.infinity,
        margin: const EdgeInsets.only(right: 8.0,),
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: Center(
          child: Icon(
            player.value.fullScreen
                ? Icons.fullscreen_exit
                : Icons.fullscreen,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// 倍数按钮
  GestureDetector _buildSpeedBtn() {
    String text = _speed.toString() + 'X';
    if (_speed == 1.0) {
      text = '倍速';
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _hideSpeedStu = !_hideSpeedStu;
        });
      },
      child: Container(
        alignment: Alignment.center,
        height: double.infinity,
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
        ),
      ),
    );
  }

  /// 选集按钮
  GestureDetector _buildPlaylistBtn() {
    return GestureDetector(
      onTap: _openPlaylist,
      child: Container(
        alignment: Alignment.center,
        height: double.infinity,
        margin: const EdgeInsets.only(right: 8.0),
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
        ),
        child: Text(
          '选集',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
        ),
      ),
    );
  }

  /// 底部操作栏
  AnimatedOpacity _buildBottomBar() {
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue =
    _seekPos > 0 ? _seekPos : _currentPos.inMilliseconds.toDouble();
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);

    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1.0,
      duration: Duration(milliseconds: 300),
      child: SafeArea(
        bottom: player.value.fullScreen,
        child: Container(
          height: barHeight,
          color: Colors.black26,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildPlayStateBtn(),
              if (widget.allowMute)
                _buildMuteBtn(),
              SizedBox(width: 8,),
              // 已播放时间
              Text(
                '${_duration2String(_currentPos)}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
              // 播放进度
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 8, left: 8),
                  child: CustomSlider(
                    colors: CustomSliderColors(
                      cursorColor: Theme.of(context).primaryColor,
                      playedColor: Theme.of(context).primaryColor,
                    ),
                    value: currentValue,
                    cacheValue: _bufferPos.inMilliseconds.toDouble(),
                    min: 0.0,
                    max: duration,
                    onChanged: (v) {
                      _startHideTimer();
                      setState(() {
                        _seekPos = v;
                      });
                    },
                    onChangeEnd: (v) {
                      setState(() {
                        player.seekTo(v.toInt());
                        _currentPos = Duration(milliseconds: _seekPos.toInt());
                        _seekPos = -1;
                      });
                    },
                  ),
                ),
              ),
              // 总播放时间
              Text(
                '${_duration2String(_duration)}',
                style: TextStyle(
                  fontSize: 14.0,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8,),
              if (widget.player.value.fullScreen)
                _buildSpeedBtn(),
              if (widget.player.value.fullScreen && widget.playlistBuilder != null)
                _buildPlaylistBtn(),
              if (widget.allowFullScreen)
                _buildExpandBtn(),
            ],
          )
        ),
      ),
    );
  }

  /// 顶部返回按钮
  GestureDetector _buildTopBackBtn() {
    return GestureDetector(
      onTap: () {
        if (player.value.fullScreen) {
          player.exitFullScreen();
        } else {
          if (widget.pageContext == null) return;
          player.stop();
          Navigator.pop(widget.pageContext!);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
        ),
        child: Icon(Icons.arrow_back, color: Colors.white,),
      ),
    );
  }

  /// 顶部导航条
  Widget _buildTopBar() {
    return AnimatedOpacity(
      opacity: _hideStuff ? 0.0 : 1,
      duration: Duration(milliseconds: 300),
      child: Container(
        height: player.value.fullScreen ? barHeight : 40,
        color: Colors.black26,
        child: Row(
          children: <Widget>[
            _buildTopBackBtn(),
            Expanded(
              child: Container(
                child: Text(
                  widget.playerTitle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // 操作栏
            widget.actionWidget ?? Container(),
          ],
        ),
      ),
    );
  }

  /// 居中播放按钮
  Widget _buildCenterPlayBtn() {
    if (!player.value.fullScreen) return Container();
    return CenterPlayButton(
      backgroundColor: Colors.black38,
      iconColor: Colors.white,
      isFinished: player.value.state == FijkState.completed,
      isPlaying: player.value.state == FijkState.started,
      show: !_isTouch && !_hideStuff,
      onPressed: _playOrPause,
    );
  }

  /// 加载中
  Widget _buildLoading() {
    return SizedBox(
      width: 50,
      height: 50,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }

  /// 播放错误状态
  Widget _buildErrorWidget() {
    return Container(
      color: Colors.transparent,
      height: double.infinity,
      width: double.infinity,
      child: Column(
        children: [
          Container(
            alignment: Alignment.centerLeft,
            child: _buildTopBackBtn(),
          ),
          Expanded(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 失败图标
                  Icon(
                    Icons.error,
                    size: 60,
                    color: Colors.white,
                  ),
                  // 错误信息
                  Text(
                    "播放失败，请${widget.onReplay == null ? '稍后' : '点击'}重试",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 20),
                  // 重试
                  if (widget.onReplay != null)
                    OutlinedButton(
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.white)
                          ),
                        ),
                        side: MaterialStateProperty.all(BorderSide(color: Colors.white)),
                        elevation: MaterialStateProperty.all(0),
                        backgroundColor: MaterialStateProperty.all(Colors.black12)
                      ),
                      onPressed: widget.onReplay,
                      child: Text(
                        "点击重试",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 滑动进度时间显示
  Widget _buildDragProgressTime() {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(5),
        ),
        color: Color.fromRGBO(0, 0, 0, 0.8),
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: Text(
          '${_duration2String(_dragPos)} / ${_duration2String(_duration)}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
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
      iconData = !_isDragVerLeft! ? Icons.volume_mute : Icons.brightness_low;
    } else if (_updateDragVarVal! < 0.5) {
      iconData = !_isDragVerLeft! ? Icons.volume_down : Icons.brightness_medium;
    } else {
      iconData = !_isDragVerLeft! ? Icons.volume_up : Icons.brightness_high;
    }
    // 显示，亮度 || 音量
    return Card(
      color: Color.fromRGBO(0, 0, 0, 0.8),
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
              width: 100,
              height: 3,
              margin: EdgeInsets.only(left: 8),
              child: LinearProgressIndicator(
                value: _updateDragVarVal,
                backgroundColor: Colors.white54,
                valueColor: AlwaysStoppedAnimation(Colors.lightBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 倍数列表框
  Widget _buildSpeedList() {
    double speedMargin = 16;
    if (widget.allowFullScreen) {
      speedMargin += 40;
    }
    if (widget.allowMute) {
      speedMargin += 40;
    }
    if (widget.playlistBuilder != null) {
      speedMargin += 40;
    }
    return Positioned(
      right: speedMargin,
      bottom: barHeight + 5,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          children: widget.speedList.reversed.map((val) => Ink(
            child: InkWell(
              onTap: () async {
                if (_speed == val) return null;
                await player.setSpeed(val);
                setState(() {
                  _speed = val;
                  _hideSpeedStu = true;
                });
              },
              child: Container(
                alignment: Alignment.center,
                width: 50,
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white54)
                  )
                ),
                child: Text(
                  val.toString() + "X",
                  style: TextStyle(
                    color: _speed == val ? Colors.blue : Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          )).toList(),
        ),
      )
    );
  }

  /// 剧集抽屉
  Widget _buildPlayDrawer() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text('选集'),
      ),
      backgroundColor: Colors.black54,
      body: widget.playlistBuilder!.call(context, _closePlaylist),
    );
  }

  /// 锁屏按钮
  Widget _buildLockBtn() {
    return Align(
      alignment: Alignment.centerLeft,
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 1,
        duration: Duration(milliseconds: 300),
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _lockStuff  = !_lockStuff;
                });
                _startHideLockTimer();
              },
              child: Icon(_lockStuff ? Icons.lock_outline : Icons.lock_open, color: Colors.white, size: 30,),
            )
        ),
      ),
    );
  }

  /// 显示操作区域
  Widget _buildHitArea() {
    return GestureDetector(
      onTap: _cancelAndRestartTimer,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Stack(
          children: [
            // 播放器顶部控制器
            if (widget.showTopCon)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),
            // 顶部显示 (快进时间、音量、亮度)
            if (_isTouch || _varTouchInitSuc)
              Positioned(
                top: barHeight + 20,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 显示左右滑动快进时间的块
                    if (_isTouch)
                      _buildDragProgressTime(),
                    // 显示上下滑动音量亮度
                    if (_varTouchInitSuc)
                      _buildDragVolumeAndBrightness(),
                  ],
                ),
              ),
            // 中间按钮
            Align(
              alignment: Alignment.center,
              child: !_prepared || _buffering
                ? _buildLoading()
                : _buildCenterPlayBtn(),
            ),
            // 倍数选择
            if (!_hideSpeedStu)
              _buildSpeedList(),
            // 锁按钮
            if (player.value.fullScreen)
              _buildLockBtn(),
            // 播放器底部控制器
            if (_prepared)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(),
              ),
          ],
        )
      ),
    );
  }

  /// 右侧框
  Widget _buildMoreFullScreen() {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _closePlaylist,
            ),
          ),
          Container(
            child: SlideTransition(
              position: _animation,
              child: Container(
                height: window.physicalSize.height,
                width: 320,
                child: _buildPlayDrawer(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = Rect.fromLTWH(
      0,
      0,
      widget.viewSize.width,
      widget.viewSize.height,
    );

    Widget child;

    // 是否锁定
    if (_lockStuff == true) {
      child = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _cancelAndRestartLockTimer,
        child: Container(
          child: AnimatedOpacity(
            opacity: _hideLockStuff ? 0.0 : 1,
            duration: Duration(milliseconds: 300),
            child: _buildLockBtn(),
          ),
        ),
      );
    } else {
      // 抽屉状态true 并且 是全屏状态
      if (_drawerState == true && widget.player.value.fullScreen) {
        child = _buildMoreFullScreen();
      } else if (player.state == FijkState.error) {
        child = _buildErrorWidget();
      } else {
        child = _buildHitArea();
      }
    }
    return WillPopScope(
      child: Positioned.fromRect(
        rect: rect,
        child: child,
      ),
      onWillPop: () async {
        if (_lockStuff) return false;
        return true;
      }
    );
  }
}