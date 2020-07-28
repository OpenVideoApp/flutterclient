import 'dart:ui';

import 'package:flutter/material.dart';

enum NavInfoType { Tab, Video, Overlay }

class NavInfo {
  NavInfoType type;
  int from, to;

  NavInfo({@required this.type, @required this.from, @required this.to});
}

class VideoNavInfo extends NavInfo {
  int selectedVideo;

  VideoNavInfo({
    NavInfoType type,
    int from,
    int to,
    @required this.selectedVideo,
  }) : super(type: type, from: from, to: to);
}

// Applies bold formatting to tags
Widget formatText(String text) {
  List<String> words = text.split(" ");
  List<TextSpan> formattedWords = [];

  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.indexOf("#") == 0 || word.indexOf("@") == 0) {
      formattedWords.add(
        TextSpan(
          text: word,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      formattedWords.add(TextSpan(text: word));
    }
    if (i < words.length) formattedWords.add(TextSpan(text: " "));
  }

  return RichText(
    text: TextSpan(
      text: "",
      style: TextStyle(
        color: Colors.white,
        fontSize: 15,
      ),
      children: formattedWords,
    ),
  );
}

final List<String> numberSuffixes = ["", "K", "M", "B", "T"];

String compactInt(int number) => compactDouble(number.toDouble());

String compactDouble(double number, {int iteration = 0}) {
  double n = num.parse(number.toStringAsFixed(1));
  bool isInt = n != n.toInt().toDouble();
  if (n < 100 && isInt) {
    return n.toString() + numberSuffixes[iteration];
  } else if (n < 1000) {
    return n.toInt().toString() + numberSuffixes[iteration];
  } else if (n < 10000 && iteration == 0) return n.toInt().toString();
  return compactDouble(n / 1000, iteration: iteration + 1);
}

PageRouteBuilder zoomTo(Widget Function(BuildContext, Animation<double>, Animation<double>) pageBuilder) {
  return PageRouteBuilder(
    pageBuilder: pageBuilder,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var tween = Tween(begin: 0.0, end: 1.0);
      var anim = animation.drive(tween);
      return ScaleTransition(
        scale: anim,
        child: child,
      );
    },
    transitionDuration: Duration(milliseconds: 100),
  );
}

Widget Function(BuildContext, Animation<double>, Animation<double>, Widget) slideFrom(double x, double y) {
  return (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    var begin = Offset(x, y);
    var end = Offset.zero;

    var tween = Tween(begin: begin, end: end);
    var offsetAnimation = animation.drive(tween);

    return SlideTransition(
      position: offsetAnimation,
      child: child,
    );
  };
}
