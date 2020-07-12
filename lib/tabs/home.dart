import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/tabs/video_screen.dart';
import 'package:flutterclient/video.dart';
import 'package:video_player/video_player.dart';

import '../uihelpers.dart';

class HomeTab extends StatefulWidget {
  final Stream shouldTriggerChange;

  HomeTab({@required this.shouldTriggerChange});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  StreamSubscription _streamSubscription;

  final List<Video> _videos = [];

  PageController _pageController;

  // Used to track the index of the first and last video currently loaded
  int _oldestVideo = 0;
  int _latestVideo = 0;

  int _selectedPage = 0;
  bool _paused;

  Future<void> setupVideo(Video video) {
    video.initControllers(() => setState(() {}));
    return video.controllerFuture;
  }

  @override
  void initState() {
    super.initState();

    _paused = false;

    fetchVideos(count: 5).then((videos) {
      for (int video = 0; video < videos.length; video++) {
        setupVideo(videos[video]).then((_) {
          setState(() {
            _latestVideo = _videos.length;
            _videos.add(videos[video]);

            // If this is the first video, start playing it
            if (_videos.length == 1 && !videos[video].controller.value
              .isPlaying) {
              videos[video].controller.play();
            }
          });
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_videos.length > _pageController.page.toInt()) {
        setState(() {
          print("Playing video ${_pageController.page}");
          _videos[_pageController.page.toInt()].controller.play();
        });
      }
    });

    _pageController = PageController();

    _streamSubscription = widget.shouldTriggerChange.listen((info) {
      if (_videos.length > _selectedPage) {
        if (_videos[_selectedPage].active) {
          if (info.from == 0 && info.to != 0) {
            if (_videos[_selectedPage].controller.value.isPlaying) {
              _videos[_selectedPage].controller.pause();
            }
          } else if (info.to == 0 && info.from != 0) {
            if (!_paused && !_videos[_selectedPage].controller.value
              .isPlaying) {
              _videos[_selectedPage].controller.play();
            }
          }
        }
      }
    });
  }

  void toggleVideo(Video video) {
    setState(() {
      if (video.controller.value.isPlaying) {
        video.controller.pause();
        _paused = true;
      }
      else {
        video.controller.play();
        _paused = false;
      }
    });
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

  Widget makeVideo(Video video) {
    double progress = 0;
    if (video.controller.value.duration != null) {
      progress = video.controller.value.position.inMilliseconds
        .toDouble() / video.controller.value.duration.inMilliseconds
        .toDouble();
    }

    return fullscreenAspectRatio(
      context: context,
      aspectRatio: video.controller.value.aspectRatio,
      video: (w, h) {
        return FutureBuilder(
          future: video.controllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Container(
                width: video.controller.value.size.width,
                height: video.controller.value.size.height,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => toggleVideo(video),
                  onDoubleTap: () {
                    setState(() {
                      video.liked = true;
                    });
                  },
                  child: VideoPlayer(video.controller)
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
        if (!video.controller.value.isPlaying && _paused)
          Center(
            child: GestureDetector(
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 100
              ),
              onTap: () => toggleVideo(video),
            ),
          )
        ,
        Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4
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
                child: formatText(video.desc)
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
                                controller: video.soundScrollController,
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  video.sound.desc,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15
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
                          image: NetworkImage("https://open-video.s3-ap-southeast-2.amazonaws.com/raphydaphy.jpg")
                        )
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.all(5)
                    ),
                    formatText("@raphydaphy \n4831 Followers")
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

  Widget makeEmptyVideo() {
    return Container(
      alignment: Alignment.center,
      color: Colors.black,
      child: CircularProgressIndicator()
    );
  }

  List<Widget> getVideos() {
    List<Widget> videos = [];
    for (int video = 0; video < _videos.length; video++) {
      if (_videos[video].active) {
        videos.add(makeVideo(_videos[video]));
      } else {
        videos.add(makeEmptyVideo());
      }
    }

    if (_videos.length == 0) {
      videos.add(makeEmptyVideo());
    }
    return videos;
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      children: getVideos(),
      onPageChanged: (page) {
        setState(() {
          Video oldVideo = _videos[_selectedPage];
          Video newVideo = _videos[page];

          if (oldVideo.active) {
            oldVideo.controller.pause();
            oldVideo.controller.seekTo(Duration.zero);
          }

          if (newVideo.active) {
            _videos[page].controller.play();
          }

          // Always load at least five videos in advance
          if (page > _selectedPage && _selectedPage > _latestVideo - 5) {
            // Load from the server if no unloaded videos are left
            if (_selectedPage > _videos.length - 5) {
              fetchVideos().then((videos) {
                setupVideo(videos[0]).then((_) {
                  setState(() {
                    _latestVideo = _videos.length;
                    _videos.add(videos[0]);
                  });
                });
              });
            } else {
              /*
              // Reload a previously loaded video
              Video video = _videos[_latestVideo + 1];
              setupVideo(video).then((_) {
                setState(() {
                  _latestVideo++;
                  video.active = true;
                });
              });
              */
            }

            // Unload old videos
            if (_oldestVideo + 3 < _selectedPage) {
              if (_videos[_oldestVideo].active) {
                _videos[_oldestVideo].active = false;
                _videos[_oldestVideo].controller.dispose();
                _oldestVideo++;
              }
            }
          }

          // Unload videos when scrolling backwards
          if (page < _selectedPage && _latestVideo- 6 > _selectedPage) {
            if (_videos[_latestVideo].active) {
              _videos[_latestVideo].active = false;
              _videos[_latestVideo].controller.dispose();
              _latestVideo--;
            }
          }

          _paused = false;
          _selectedPage = page;
        });
      }
    );
  }

  @override
  void dispose() {
    for (int video = 0; video < _videos.length; video++) {
      if (_videos[video].active) _videos[video].controller.dispose();
    }
    _pageController.dispose();
    _streamSubscription.cancel();
    super.dispose();
  }
}