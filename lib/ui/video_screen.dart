import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/video.dart';
import 'package:flutterclient/logging.dart';

class VideoScreenController {
  final int index;
  final Video video;

  bool active;
  bool selected;
  bool paused;

  VideoPlayerController _controller;
  Future<void> future;

  VoidCallback callback;

  VideoScreenController({
    @required this.index,
    @required this.video,
    this.active = true,
    this.selected = false,
    this.paused = false,
    this.callback
  }) {
    if (active) {
      init();
    }
  }

  bool isPlaying() {
    return active ? _controller.value.isPlaying : false;
  }

  void toggle() {
    if (isPlaying())
      pause();
    else
      play();
  }

  void play() {
    if (active) {
      _controller.play();
      paused = false;
    }
  }

  void pause({bool forced = false}) {
    if (active) {
      _controller.pause();
      if (!forced) paused = true;
    }
  }

  VideoPlayer createPlayer() {
    return new VideoPlayer(_controller);
  }

  VideoPlayerValue get value {
    return _controller.value;
  }

  void unload() {
    logger.i("Unloaded controller $index");
    if (!active) return;
    _controller.dispose();
    active = false;
  }

  void init() {
    _controller = new VideoPlayerController.network(video.src);
    _controller.setLooping(true);
    future = this._controller.initialize();

    future.then((_) {
      active = true;
      if (selected && !paused) {
        _controller.play();
        if (callback != null) callback();
      }
    });
  }

  void update(NavInfo info) {
    if (info.type == NavInfoType.Video) {
      selected = index == info.to;
      int distance = index - info.to;
      if (active) {
        if (selected && !paused) {
          _controller.play();
        } else if (index == info.from) {
          paused = false;
          _controller.pause();
          _controller.seekTo(Duration.zero);
        } else if (distance < -3 || distance > 5) {
          unload();
        }
      } else if (distance > -3 && distance < 5) {
        logger.i("Reloaded controller #$index");
        init();
      }
    } else if (info.type == NavInfoType.Tab) {
      if (active && selected && !paused) {
        if (info.from == 0 && info.to != 0) {
          _controller.pause();
        } else if (info.to == 0 && info.from != 0) {
          _controller.play();
        }
      }
    }
  }
}

class VideoScreen extends StatefulWidget {
  final VideoScreenController controller;

  VideoScreen(this.controller);

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  ScrollController _soundScrollController;

  @override
  void initState() {
    super.initState();
    _soundScrollController = new ScrollController(

    );
  }

  Widget makeVideoButton({IconData icon, String text, Color color, VoidCallback callback}) {
    if (color == null) color = Colors.white;
    return GestureDetector(
      onTap: callback,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              icon,
              size: 35,
              color: color
            ),
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15
              )
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.active) return makeEmptyVideo();

    double progress = 0;
    if (widget.controller.value.duration != null) {
      progress = widget.controller.value.position.inMilliseconds
        .toDouble() / widget.controller.value.duration.inMilliseconds
        .toDouble();
    }

    Video video = widget.controller.video;

    return fullscreenAspectRatio(
      context: context,
      aspectRatio: widget.controller.value.aspectRatio,
      video: (w, h) {
        return FutureBuilder(
          future: widget.controller.future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                width: widget.controller.value.size.width,
                height: widget.controller.value.size.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => setState(() => widget.controller.toggle()),
                  onDoubleTap: () {
                    setState(() {
                      video.liked = true;
                    });
                  },
                  child: widget.controller.createPlayer()
                )
              );
            } else {
              return Center(
                child: CircularProgressIndicator()
              );
            }
          }
        );
      },
      stack: <Widget>[
        if (!widget.controller.isPlaying() && widget.controller.paused) Center(
          child: GestureDetector(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 100
            ),
            onTap: () => setState(() => widget.controller.toggle()),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 2,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
            )
          )
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            children: <Widget>[
              Container(
                alignment: Alignment.bottomLeft,
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: formatText(widget.controller.video.desc)
              ),
              Container(
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.music_note,
                              color: Colors.white,
                              size: 40
                            ),
                            Expanded(
                              child: SingleChildScrollView(
                                controller: _soundScrollController,
                                scrollDirection: Axis.horizontal,
                                child: DefaultTextStyle(
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment
                                      .start,
                                    children: <Widget>[
                                      formatText("original sound - @${video
                                        .sound.user.name}"),
                                      Text(video.sound.desc)
                                    ]
                                  )
                                )
                              )
                            )
                          ]
                        )
                      )
                    ),
                    makeVideoButton(
                      icon: Icons.favorite,
                      text: compactNumber(video.likes),
                      color: video.liked ? Colors.red : Colors.white,
                      callback: () {
                        print("Liked a video");
                        setState(() {
                          video.liked = !video.liked;
                        });
                      }
                    ),
                    makeVideoButton(
                      icon: FontAwesome.comment_lines_solid,
                      text: compactNumber(video.comments),
                      callback: () {
                        print("Commented on a video");
                      }
                    ),
                    makeVideoButton(
                      icon: FontAwesome.share_solid,
                      text: compactNumber(video.shares),
                      callback: () {
                        print("Shared a video");
                      }
                    )
                  ]
                )
              )
            ]
          )),
        Container(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  print("Clicked a profile");
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          fit: BoxFit.fill,
                          image: NetworkImage(video.user.profilePictureUrl)
                        )
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.all(5)
                    ),
                    formatText("@${video.user.name} \n4983 Followers")
                  ]
                )
              ),
              GestureDetector(
                onTap: () {
                  print("Reported a Video");
                },
                child: Icon(
                  FontAwesome.ellipsis_h_regular,
                  size: 40,
                  color: Colors.white
                )
              )
            ]
          )
        )
      ]
    );
  }

  @override
  void dispose() {
    _soundScrollController.dispose();
    super.dispose();
  }
}

Widget makeEmptyVideo() {
  return Container(
    alignment: Alignment.center,
    color: Colors.black,
    child: CircularProgressIndicator()
  );
}

Widget fullscreenAspectRatio({
  BuildContext context,
  double aspectRatio,
  Widget Function(double width, double height) video,
  List<Widget> stack
}) {
  MediaQueryData query = MediaQuery.of(context);

  double width = query.size.width;
  double height = query.size.height - query.padding.top - query.padding
    .bottom;

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
                child: video(videoWidth, videoHeight)
              )
            )
          )
        ),
        Stack(
          children: stack
        )
      ]
    )
  );
}