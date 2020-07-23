import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/ui/widget/user_profile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/widget/comments_popup.dart';

class VideoScreenController {
  final int index;
  final Video video;

  bool active;
  bool selected;
  bool paused;

  DateTime startedPlayingAt;
  int secondsWatched = 0;

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
      logger.i("Playing video #$index");
      _controller.play();
      paused = false;
      startedPlayingAt = DateTime.now();
    } else
      logger.w("Tried to play inactive video #$index");
  }

  void pause({bool forced = false}) {
    if (active) {
      logger.i("Paused video #$index");
      _controller.pause();
      if (startedPlayingAt != null) {
        secondsWatched += DateTime
          .now()
          .difference(startedPlayingAt)
          .inSeconds;
      }
      if (!forced) paused = true;
    }
  }

  VideoPlayer createPlayer() {
    return new VideoPlayer(_controller);
  }

  VideoPlayerController get controller {
    return _controller;
  }

  VideoPlayerValue get value {
    return _controller.value;
  }

  Future<double> get progress {
    if (active && _controller.value.initialized) {
      return _controller.position.then((position) {
        double duration = _controller.value.duration.inMilliseconds.toDouble();
        return position.inMilliseconds.toDouble() / duration;
      });
    } else
      return Future<double>(() => 0);
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
          play();
        } else if (index == info.from) {
          paused = false;
          if (_controller.value.initialized) {
            pause(forced: true);
            _controller.seekTo(Duration.zero);

            graphqlClient.value.mutate(MutationOptions(
              documentNode: gql("""
                mutation WatchVideo(\$videoId: String!, \$seconds: Int!) {
                  watchVideo(videoId: \$videoId, seconds: \$seconds) {
                    ... on WatchData {seconds}
                    ... on APIError {error}
                  }
                }
              """),
              variables: {
                "videoId": video.id,
                "seconds": secondsWatched
              }
            )).then((result) {
              var watch = result.data["watchVideo"];
              if (watch["error"] != null)
                logger.w("Failed to add watch data:", watch["error"]);
              else
                logger.i("Added watch data to video '${video
                  .id}', bring total time to ${watch["seconds"]} seconds");
            });
            secondsWatched = 0;
          }
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
          pause(forced: true);
        } else if (info.to == 0 && info.from != 0) {
          play();
        }
      }
    }
  }
}

Widget _makeVideoButton({IconData icon, double iconScale = 1, String text, Color color, VoidCallback callback}) {
  if (color == null) color = Colors.white;
  return GestureDetector(
    onTap: callback,
    child: Container(
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Transform.scale(
            scale: iconScale,
            child: Icon(
              icon,
              size: 35,
              color: color
            )
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
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300)
    );

    _growAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween(
            begin: 1,
            end: 1.2
          ),
          weight: 1
        ),
        TweenSequenceItem(
          tween: Tween(
            begin: 1.2,
            end: 1
          ),
          weight: 2
        )
      ]
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0, 1)
      )
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
        return _makeVideoButton(
          icon: Icons.favorite,
          iconScale: _growAnimation.value,
          text: compactInt(widget.video.likes),
          color: widget.video.liked ? Colors.red : Colors.white,
          callback: () =>
            setState(() {
              widget.video.setLiked(!widget.video.liked);
            })
        );
      }
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    widget.video.likeCallback = null;
    super.dispose();
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
  PersistentBottomSheetController _commentSheetController;

  @override
  void initState() {
    super.initState();
    _soundScrollController = new ScrollController();
  }

  void showComments() {
    if (_commentSheetController != null) return;

    var topScaffold = Scaffold.of(Scaffold
      .of(context)
      .context);

    CommentsPopupNotification().dispatch(context);
    _commentSheetController = topScaffold.showBottomSheet(
        (context) {
        return NotificationListener(
          onNotification: (notification) {
            if (notification is CommentsPopupNotification) {
              _commentSheetController.close();
              return true;
            } else
              return false;
          },
          child: CommentsPopup(widget.controller.video)
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15)
        )
      ),
      backgroundColor: Colors.white
    );

    _commentSheetController.closed.then((_) {
      _commentSheetController = null;
      CommentsPopupNotification(visible: false).dispatch(context);
    });
  }

  bool canInteract() {
    if (_commentSheetController != null) {
      _commentSheetController.close();
      return false;
    } else
      return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.active || !widget.controller.value.initialized)
      return makeEmptyVideo();

    Video video = widget.controller.video;

    // TODO: video gets pushed up when keyboard is opened
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
                  onTap: () {
                    if (!canInteract()) return;
                    setState(() => widget.controller.toggle());
                  },
                  onDoubleTap: () {
                    if (!canInteract()) return;
                    setState(() {
                      video.setLiked(true);
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
            onTap: () {
              if (!canInteract()) return;
              setState(() => widget.controller.toggle());
            }
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 2,
            child: LinearVideoProgressIndicator(
              controller: widget.controller,
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
                              child: AutoScrollingText(
                                speed: 0.5,
                                padding: 15,
                                text: <String>[
                                  "original sound - @${video.sound.user.name}",
                                  video.sound.desc
                                ]
                              )
                            )
                          ]
                        )
                      )
                    ),
                    LikeButton(
                      video: video
                    ),
                    _makeVideoButton(
                      icon: FontAwesome.comment_lines_solid,
                      text: compactInt(video.comments),
                      callback: showComments
                    ),
                    _makeVideoButton(
                      icon: FontAwesome.share_solid,
                      text: compactInt(video.shares),
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
                  if (!canInteract()) return;
                  print("Clicked a profile");
                },
                child: Row(
                  children: <Widget>[
                    UserProfileIcon(
                      user: video.user,
                      size: 40
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
                  if (!canInteract()) return;
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