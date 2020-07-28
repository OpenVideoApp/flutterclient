import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/ui/widget/video/controller.dart';

class EmptyVideo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: CircularProgressIndicator(),
    );
  }
}


class LikeButton extends StatefulWidget {
  final Video video;

  LikeButton({@required this.video});

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<double> _growAnimation;

  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 300));

    _growAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1, end: 1.2), weight: 1),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.2,
            end: 1,
          ),
          weight: 2,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0, 1),
      ),
    );

    widget.video.likeCallback = () {
      _controller.forward(from: 0);
    };
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget child) {
        return VideoButton(
          icon: Icons.favorite,
          iconScale: _growAnimation.value,
          text: compactInt(widget.video.likes),
          color: widget.video.liked ? Colors.red : Colors.white,
          onPressed: () => setState(() {
            widget.video.setLiked(!widget.video.liked);
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.video.likeCallback = null;
    super.dispose();
  }
}


class VideoButton extends StatefulWidget {
  final IconData icon;
  final double iconScale;
  final String text;
  final Color color;
  final VoidCallback onPressed;

  VideoButton({@required this.icon, this.iconScale = 1, @required this.text, this.color = Colors.white, this.onPressed,});

  @override
  _VideoButtonState createState() => _VideoButtonState();
}

class _VideoButtonState extends State<VideoButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Transform.scale(
              scale: widget.iconScale,
              child: Icon(
                widget.icon,
                size: 35,
                color: widget.color,
              ),
            ),
            Text(
              widget.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullscreenAspectRatio extends StatelessWidget {
  final double aspectRatio;
  final Widget Function(double width, double height) video;
  final List<Widget> children;

  FullscreenAspectRatio({this.aspectRatio = 1.8, this.video, this.children});

  @override
  Widget build(BuildContext context) {
    MediaQueryData query = MediaQuery.of(context);

    double width = query.size.width;
    double height = query.size.height - query.padding.top - query.padding.bottom;

    double videoWidth = width;
    double videoHeight = videoWidth / aspectRatio;

    if (videoHeight < height) {
      videoHeight = height - 56;
      videoWidth = videoHeight * aspectRatio;

      if (videoWidth < width) {
        videoWidth = width;
        videoHeight = videoWidth / aspectRatio;
      }
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.bottomCenter,
      child: Stack(
        children: <Widget>[
          Center(
            child: ClipRect(
              child: OverflowBox(
                maxWidth: videoWidth,
                maxHeight: videoHeight,
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.center,
                  child: video(videoWidth, videoHeight),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: children,
            ),
          ),
        ],
      ),
    );
  }
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
      backgroundColor: Colors.transparent,
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
      children: lines,
    );

    var padding = Padding(
      padding: EdgeInsets.only(left: widget.padding),
    );

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: NeverScrollableScrollPhysics(),
      child: Row(
        key: _key,
        children: <Widget>[col, padding, col, padding, col, padding],
      ),
    );
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}