import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:video_player/video_player.dart';

void main() {
  // debugPaintSi+zeEnabled = true;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "OpenVideo",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: VideoPlayerScreen()
    );
  }
}

class VideoPlayerScreen extends StatefulWidget {
  VideoPlayerScreen({Key key}) : super(key: key);

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  final List<String> _videoLinks = [
    "https://open-video.s3-ap-southeast-2.amazonaws.com/cah-ad.mp4",
    "https://open-video.s3-ap-southeast-2.amazonaws.com/dorime.mp4",
    "https://open-video.s3-ap-southeast-2.amazonaws.com/mario_piano.mp4",
    "https://open-video.s3-ap-southeast-2.amazonaws.com/portland.mp4"
  ];

  List<VideoPlayerController> _videoControllers;
  List<Future<void>> _videoControllerFutures;
  PageController _pageController;

  int _selectedTab = 0;
  int _selectedPage = 0;
  bool _paused;

  @override
  void initState() {
    super.initState();

    _videoControllers = List();
    _videoControllerFutures = List();
    _paused = false;

    for (int video = 0; video < _videoLinks.length; video++) {
      _videoControllers.add(new VideoPlayerController.network(_videoLinks[video]));
      _videoControllers[video]..setLooping(true)..addListener(() {
        setState(() { });
      });
      _videoControllerFutures.add(_videoControllers[video].initialize());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _videoControllers[0].play();
      });
    });

    _pageController = PageController();
  }

  Widget makeVideo(int id) {
    ThemeData theme = Theme.of(context);
    MediaQueryData query = MediaQuery.of(context);

    double width = query.size.width;
    double height = query.size.height - query.padding.top - query.padding.bottom;

    double aspectRatio = _videoControllers[id].value.aspectRatio;

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

    double progress = 0;
    if (_videoControllers[id].value.duration != null) {
      progress = _videoControllers[id].value.position.inMilliseconds.toDouble() / _videoControllers[id].value.duration.inMilliseconds.toDouble();
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.bottomCenter,
      child: Stack(children: <Widget>[
        Center(
          child: ClipRect(
            child: OverflowBox(
              maxWidth: videoWidth,
              maxHeight: videoHeight,
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.fitWidth,
                alignment: Alignment.center,
                child: FutureBuilder(
                  future: _videoControllerFutures[id],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        width: _videoControllers[id].value.size.width,
                        height: _videoControllers[id].value.size.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              if (_videoControllers[id].value.isPlaying) {
                                _videoControllers[id].pause();
                                _paused = true;
                              }
                              else {
                                _videoControllers[id].play();
                                _paused = false;
                              }
                            });
                          },
                          child: VideoPlayer(_videoControllers[id])
                        )
                      );
                    } else {
                      return Center(
                          child: CircularProgressIndicator()
                      );
                    }
                  }
                )
              )
            )
          )
        ),
        if (!_videoControllers[id].value.isPlaying && _paused) Center(
          child: Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 100
          )
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 4
          )
        )
      ])
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
          child: NotificationListener(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  setState(() {
                    _videoControllers[_selectedPage].pause();
                  });
                } else if (notification is ScrollEndNotification && !_paused) {
                  setState(() {
                    _videoControllers[_selectedPage].play();
                  });
                }
                return false;
              },
              child: PageView(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                children: [
                  makeVideo(0),
                  makeVideo(1),
                  makeVideo(2),
                  makeVideo(3)
                ],
                onPageChanged: (page) {
                  setState(() {
                    _videoControllers[_selectedPage].seekTo(Duration.zero);
                    _paused = false;
                    _selectedPage = page;
                  });
                }
              )
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text("Home")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            title: Text("Search")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            title: Text("Create")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            title: Text("Chat")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text("Profile")
          )
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedTab,
        showUnselectedLabels: true,
        selectedItemColor: theme.textTheme.subtitle1.color,
        unselectedItemColor: theme.textTheme.headline1.color,
        onTap: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    for (int video = 0; video < _videoLinks.length; video++) {
      _videoControllers[video].dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}