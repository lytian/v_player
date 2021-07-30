import 'package:flutter/material.dart';

class AnimatedFloatingActionButton extends StatefulWidget {
  AnimatedFloatingActionButton({Key? key, required this.onPress}) : super(key: key);

  final Function onPress;

  @override
  AnimatedFloatingActionButtonState createState() => AnimatedFloatingActionButtonState();
}

class AnimatedFloatingActionButtonState extends State<AnimatedFloatingActionButton> with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<Offset> _translateAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _scaleAnimation;

  bool isShow = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: Duration(milliseconds: 300), vsync: this);
    _translateAnimation = Tween(begin: Offset(0.0, 0.0), end: Offset(0.75, 0.0)).animate(_controller);
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1).animate(_controller);
    _scaleAnimation = Tween<double>(begin: 1, end: 0.8).animate(_controller);
  }

  void show() {
    isShow = true;
    _controller.reverse();
  }

  void hide() {
    isShow = false;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
          position: _translateAnimation,
          child: RotationTransition(
            turns: _rotateAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: MaterialButton(
                height: 48,
                shape: CircleBorder(),
                color: Theme.of(context).primaryColor,
                child: Icon(Icons.widgets, color: Colors.white, size: 30,),
                onPressed: () {
                  if (!this.isShow) {
                    this.show();
                    return;
                  }
                  widget.onPress();
                },
              )
            )
          )
    );
  }
}