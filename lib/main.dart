import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/video.dart';
import 'package:intl/intl.dart';
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
  final List<Video> _videos = [
    new Video(
      src: "https://open-video.s3-ap-southeast-2.amazonaws.com/cah-ad.mp4",
      desc: "I made this site so that you can play #cardsagainsthumanity despite being in #quarantine! Link in bio.",
      sound: new Sound("original sound\ncards against quarantine"),
      likes: 168302,
      comments: 3048,
      shares: 34931
    ),
    new Video(
      src: "https://open-video.s3-ap-southeast-2.amazonaws.com/dorime.mp4",
      desc: "It haunts my #dreams",
      sound: new Sound("@del0ne3r\nits pretty spooky"),
      likes: 2843967,
      comments: 28483,
      shares: 43812
    ),
    new Video(
      src: "https://open-video.s3-ap-southeast-2.amazonaws.com/mario_piano.mp4",
      desc: "My #piano cover of #mario - #gaming #toptalent",
      sound: new Sound("original sound\nmario piano cover"),
      likes: 99381,
      comments: 48313,
      shares: 13843
    ),
    new Video(
      src: "https://open-video.s3-ap-southeast-2.amazonaws.com/portland.mp4",
      desc: "All I want in life is to #play this to my #girlfriend - #lgbt #gay #guitar",
      sound: new Sound("original sound\nshe said to me (portland)"),
      likes: 2593381,
      comments: 14399,
      shares: 9931
    )
  ];

  PageController _pageController;

  int _selectedTab = 0;
  int _selectedPage = 0;
  bool _paused;

  @override
  void initState() {
    super.initState();

    _paused = false;

    for (int video = 0; video < _videos.length; video++) {
      _videos[video].initControllers(() => setState(() {}));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _videos[0].controller.play();
      });
    });

    _pageController = PageController();
  }

  void toggleVideo(int id) {
    setState(() {
      if (_videos[id].controller.value.isPlaying) {
        _videos[id].controller.pause();
        _paused = true;
      }
      else {
        _videos[id].controller.play();
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

  String compactNumber(int number) {
    return NumberFormat.compactCurrency(
      decimalDigits: 0,
      symbol: ""
    ).format(number);
  }

  Widget makeVideo(int id) {
    MediaQueryData query = MediaQuery.of(context);

    double width = query.size.width;
    double height = query.size.height - query.padding.top - query.padding
      .bottom;

    double aspectRatio = _videos[id].controller.value.aspectRatio;

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
    if (_videos[id].controller.value.duration != null) {
      progress = _videos[id].controller.value.position.inMilliseconds
        .toDouble() / _videos[id].controller.value.duration.inMilliseconds
        .toDouble();
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
                  future: _videos[id].controllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        width: _videos[id].controller.value.size.width,
                        height: _videos[id].controller.value.size.height,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => toggleVideo(id),
                          onDoubleTap: () {
                            setState(() {
                              _videos[id].liked = true;
                            });
                          },
                          child: VideoPlayer(_videos[id].controller)
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
        if (!_videos[id].controller.value.isPlaying && _paused) Center(
          child: GestureDetector(
            child: Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 100
            ),
            onTap: () => toggleVideo(id),
          ),
        ),
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
                child: formatText(_videos[id].desc)
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
                                controller: _videos[id].soundScrollController,
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  _videos[id].sound.desc,
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
                      text: compactNumber(_videos[id].likes),
                      color: _videos[id].liked ? Colors.red : Colors.white,
                      callback: () {
                        print("Liked video #${id.toString()}");
                        setState(() {
                          _videos[id].liked = !_videos[id].liked;
                        });
                      }
                    ),
                    makeVideoButton(
                      icon: FontAwesome.comment_lines_solid,
                      text: compactNumber(_videos[id].comments),
                      callback: () {
                        print("Commented on video #${id.toString()}");
                      }
                    ),
                    makeVideoButton(
                      icon: FontAwesome.share_solid,
                      text: compactNumber(_videos[id].shares),
                      callback: () {
                        print("Shared video #${id.toString()}");
                      }
                    )
                  ]
                )
              )

            ]
          )
        ),
        Container(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  print("Clicked profile on video #$id");
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
                  print("Report Video #$id");
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
      ])
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
              _videos[_selectedPage].controller.pause();
              _videos[_selectedPage].controller.seekTo(Duration.zero);
              _videos[page].controller.play();

              _paused = false;
              _selectedPage = page;
            });
          }
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
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
            icon: Icon(FontAwesome.video_plus_solid),
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
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
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
    for (int video = 0; video < _videos.length; video++) {
      _videos[video].controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }
}