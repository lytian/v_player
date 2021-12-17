import 'package:flutter/material.dart';

class NoData extends StatelessWidget {
  const NoData({Key? key, required this.tip, this.onTap}) : super(key: key);

  final String tip;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(
          flex: 2,
          child: Container(),
        ),
        GestureDetector(
          onTap: onTap,
          child: Column(
            children: <Widget>[
              SizedBox(
                width: 100.0,
                height: 100.0,
                child: Image.asset('assets/image/nodata.png'),
              ),
              Text(tip, textAlign: TextAlign.center, style: TextStyle(fontSize: 14.0, color: Colors.grey[400],),),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Container(),
        ),
      ],
    );
  }
}
