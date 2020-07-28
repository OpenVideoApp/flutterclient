import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/widget/user_profile.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/ui/widget/comments_popup.dart';
import 'package:flutterclient/ui/widget/video/components.dart';
import 'package:flutterclient/ui/widget/video/controller.dart';
import 'package:video_player/video_player.dart';

class VideoScreen extends StatefulWidget {
  final VideoScreenController controller;
  final Stream<VideoNavInfo> notifier;
  final int index;

  VideoScreen({
    @required this.controller,
    @required this.notifier,
    @required this.index,
  });

  @override
  _VideoScreenState createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  ScrollController _soundScrollController;
  PersistentBottomSheetController _commentSheetController;
  StreamSubscription<VideoNavInfo> _subscription;

  bool _selected = false, _minimised = false;

  @override
  void initState() {
    super.initState();
    _soundScrollController = new ScrollController();

    if (widget.index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selected = true;
        }
      });
    }

    widget.controller.future.then((_) {
      if (!mounted) {
        return;
      }
      if (!_minimised && _selected && !widget.controller.paused) {
        widget.controller.play();
      } else if (widget.controller.isPlaying()) {
        widget.controller.pause(forced: true);
      }
      logger.i("Loaded video #${widget.controller.video.id}");
      setState(() {});
    });

    _subscription = widget.notifier.listen((info) {
      _selected = widget.index == info.selectedVideo;
      if (info.from == info.to) {
        return;
      }

      var paused = widget.controller.paused;
      var playing = widget.controller.isPlaying();

      if (!_selected && (paused || playing)) {
        if (playing) {
          widget.controller.pause(forced: true);
        }
        if (paused) {
          setState(() {
            widget.controller.paused = false;
          });
        }
        widget.controller.restart();
      }

      var type = info.type;

      if (type == NavInfoType.Video) {
        if (info.to == widget.index) {
          widget.controller.play();
        }
      } else if (type == NavInfoType.Tab || type == NavInfoType.Overlay) {
        logger.i("Navigation to ${info.to} from ${info.from}");
        if (info.to == 0) {
          _minimised = false;
          if (_selected && !paused) {
            widget.controller.play();
          }
        } else {
          _minimised = true;
          if (playing) {
            widget.controller.pause(forced: true);
          }
        }
      }
    });
  }

  void showComments() {
    if (_commentSheetController != null) return;

    var topScaffold = Scaffold.of(Scaffold.of(context).context);

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
          child: CommentsPopup(widget.controller.video),
        );
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      backgroundColor: Colors.white,
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
    Video video = widget.controller.video;

    // TODO: video gets pushed up when keyboard is opened
    return FullscreenAspectRatio(
      aspectRatio: widget.controller.aspectRatio,
      video: (w, h) {
        return FutureBuilder(
          future: widget.controller.future,
          builder: (context, snapshot) {
            if (widget.controller.ready) {
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
                  child: VideoPlayer(widget.controller.controller),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }
        );
      },
      children: <Widget>[
        if (!widget.controller.isPlaying() && widget.controller.paused)
          Center(
            child: GestureDetector(
              child: Icon(Icons.play_arrow, color: Colors.white, size: 100),
              onTap: () {
                if (!canInteract()) return;
                setState(() => widget.controller.toggle());
              },
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 2,
            child: LinearVideoProgressIndicator(
              controller: widget.controller,
            ),
          ),
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
                child: formatText(widget.controller.video.desc),
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
                              size: 40,
                            ),
                            Expanded(
                              child: AutoScrollingText(
                                speed: 0.5,
                                padding: 15,
                                text: <String>[
                                  "original sound - @${video.sound.user.name}",
                                  video.sound.desc,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    LikeButton(
                      video: video,
                    ),
                    VideoButton(
                      icon: FontAwesome.comment_lines_solid,
                      text: compactInt(video.comments),
                      onPressed: showComments,
                    ),
                    VideoButton(
                      icon: FontAwesome.share_solid,
                      text: compactInt(video.shares),
                      onPressed: () {
                        print("Shared a video");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                      size: 40,
                    ),
                    Padding(
                      padding: EdgeInsets.all(5),
                    ),
                    formatText(
                        "@${video.user.name} \n${video.user.followers} Follower${video.user.followers == 1 ? "" : "s"}"),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (!canInteract()) return;
                  print("Reported a Video");
                },
                child: Icon(
                  FontAwesome.ellipsis_h_regular,
                  size: 40,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _commentSheetController?.close();
    _subscription.cancel();
    _soundScrollController.dispose();
    super.dispose();
  }
}
