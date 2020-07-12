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

  final List<Video> _videos = [
    new Video(
      src: "https://open-video.s3-ap-southeast-2.amazonaws.com/cah-ad.mp4",
      desc: "I made this site so that you can play #cardsagainsthumanity despite being in #quarantine! Link in bio.",
      sound: new Sound("original sound\ncards against quarantine"),
      likes: 168302,
      comments: 3048,
      shares: 34931
    )
  ];

  PageController _pageController;

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
    setupVideo(_videos[0]);

    for (int i = 0; i < 4; i++) {
      getVideo().then((video) {
        setupVideo(video).then((_) {
          setState(() {
            _videos.add(video);
          });
        });
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        print("Playing video ${_pageController.page}");
        _videos[_pageController.page.toInt()].controller.play();
      });
    });

    _pageController = PageController();

    _streamSubscription = widget.shouldTriggerChange.listen((info) {
      if (info.from == 0 && info.to != 0) {
        if (_videos[_selectedPage].controller.value.isPlaying) {
          _videos[_selectedPage].controller.pause();
        }
      } else if (info.to == 0 && info.from != 0) {
        if (!_paused && !_videos[_selectedPage].controller.value.isPlaying) {
          _videos[_selectedPage].controller.play();
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

  List<Widget> getVideos() {
    List<Widget> videos = [];
    for (int video = 0; video < _videos.length; video++) {
      videos.add(makeVideo(_videos[video]));
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
          _videos[_selectedPage].controller.pause();
          _videos[_selectedPage].controller.seekTo(Duration.zero);
          _videos[page].controller.play();

          _paused = false;
          _selectedPage = page;
        });
      }
    );
  }

  @override
  void dispose() {
    for (int video = 0; video < _videos.length; video++) {
      _videos[video].controller.dispose();
    }
    _pageController.dispose();
    _streamSubscription.cancel();
    super.dispose();
  }
}