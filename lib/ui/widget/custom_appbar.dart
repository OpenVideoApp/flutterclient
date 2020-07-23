import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget {
  final String title;
  final Widget left, right;

  CustomAppBar({
    @required this.title,
    this.left, this.right
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          this.left == null ? Container () : this.left,
          Text(
            this.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500
            )
          ),
          this.right == null ? Container() : this.right
        ]
      )
    );
  }
}