import 'package:flutter/material.dart';

class NoData extends StatelessWidget {
  NoData({required this.tip, this.onTap});

  final String tip;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
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
      ),
    );
  }
}
