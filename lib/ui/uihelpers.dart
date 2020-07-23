import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutterclient/ui/widget/video_screen.dart';

enum NavInfoType {
  Tab,
  Video,
  Profile
}

class NavInfo {
  NavInfoType type;
  int from, to;

  NavInfo({@required this.type, @required this.from, @required this.to});
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
          style: TextStyle(fontWeight: FontWeight.bold)
        )
      );
    } else {
      formattedWords.add(
        TextSpan(text: word)
      );
    }
    if (i < words.length) formattedWords.add(TextSpan(text: " "));
  }

  return RichText(
    text: TextSpan(
      text: "",
      style: TextStyle(
        color: Colors.white,
        fontSize: 15
      ),
      children: formattedWords
    )
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

class LinearVideoProgressIndicator extends StatefulWidget {
  final VideoScreenController controller;

  LinearVideoProgressIndicator({@required this.controller});

  @override
  _LinearVideoProgressIndicatorState createState() =>
    _LinearVideoProgressIndicatorState();
}

class _LinearVideoProgressIndicatorState
  extends State<LinearVideoProgressIndicator>
  with SingleTickerProviderStateMixin {
  Ticker _ticker;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _ticker = createTicker((elapsed) {
      widget.controller.progress.then((progress) {
        if (progress != _progress) {
          setState(() {
            _progress = progress;
          });
        }
      });
    });

    _ticker.start();
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: _progress,
      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      backgroundColor: Colors.transparent
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

class AutoScrollingText extends StatefulWidget {
  final List<String> text;
  final double speed;
  final double padding;

  AutoScrollingText({@required this.text, this.speed = 0.5, this.padding = 5});

  @override
  _AutoScrollingTextState createState() => _AutoScrollingTextState();
}

class _AutoScrollingTextState extends State<AutoScrollingText>
  with SingleTickerProviderStateMixin {
  GlobalKey _key = GlobalKey();
  ScrollController _scrollController;
  Ticker _ticker;
  double _scrollPos = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = new ScrollController();
    _ticker = createTicker((elapsed) => tick(elapsed));
    _ticker.start();
  }

  void tick(Duration elapsed) {
    final RenderBox renderBox = _key.currentContext.findRenderObject();
    final size = renderBox.size;

    _scrollController.jumpTo(_scrollPos);
    _scrollPos += widget.speed;

    if (_scrollPos > size.width / 3) {
      _scrollPos = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> lines = [];

    for (var line in widget.text) {
      lines.add(formatText(line));
    }

    var col = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines
    );

    var padding = Padding(
      padding: EdgeInsets.only(left: widget.padding)
    );

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(),
      child: Row(
        key: _key,
        children: <Widget>[
          col, padding, col, padding, col, padding
        ]
      )
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

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
    this.width, this.height,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero
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
          border: Border.all(color: this.borderColor)
        ),
        child: text
      )
    );
  }
}

PageRouteBuilder zoomTo(Widget Function(BuildContext, Animation<double>, Animation<double>) pageBuilder) {
  return PageRouteBuilder(
    pageBuilder: pageBuilder,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      var tween = Tween(
        begin: 0.0,
        end: 1.0
      );
      var anim = animation.drive(tween);
      return ScaleTransition(
        scale: anim,
        child: child
      );
    },
    transitionDuration: Duration(milliseconds: 100)
  );
}