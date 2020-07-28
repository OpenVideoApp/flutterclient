import 'dart:ui';

import 'package:flutter/material.dart';

class BorderedFlatButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color textColor, backgroundColor, borderColor;
  final double width, height;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Widget text;

  BorderedFlatButton({
    @required this.onTap,
    @required this.text,
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.width,
    this.height,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: this.onTap,
      child: Container(
        width: this.width,
        height: this.height,
        padding: this.padding,
        margin: this.margin,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: this.backgroundColor,
          border: Border.all(color: this.borderColor),
        ),
        child: text,
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final List<Color> colors;

  GradientButton({@required this.onPressed, this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      padding: EdgeInsets.zero,
      onPressed: this.onPressed,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.transparent),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Ink(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: this.colors == null
              ? null
              : LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            stops: [0, 1],
            colors: this.colors,
          ),
          color: this.colors != null ? null : Colors.white,
        ),
        child: Container(
          alignment: Alignment.center,
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: "Roboto",
              fontWeight: FontWeight.w500,
              fontSize: 18.0,
              color: this.colors == null ? Colors.black.withOpacity(0.5) : Colors.white,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
