import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/ui/video_screen.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/logging.dart';

class HomeTab extends StatefulWidget {
  final Stream shouldTriggerChange;

  HomeTab({@required this.shouldTriggerChange});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  StreamSubscription _streamSubscription;
  List<VideoScreenController> _videoControllers = [];
  PageController _pageController;
  int _selectedPage = 0;

  @override
  void initState() {
    super.initState();

    fetchVideos(
      context,
      count: 5
    ).then((videos) {
      for (int video = 0; video < videos.length; video++) {
        setState(() {
          _videoControllers.add(VideoScreenController(
            index: _videoControllers.length,
            video: videos[video],
            selected: _videoControllers.length == 0,
            callback: () => setState(() => {})
          ));
        });
      }
    });

    _pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int realPage = _pageController.page.toInt();
      if (_videoControllers.length > realPage) {
        _videoControllers[realPage].selected = true;
      }
    });

    _streamSubscription = widget.shouldTriggerChange.listen((info) {
      logger.i("Changed tab from ${info.from} to ${info.to}");
      if ((info.from == 0 && info.to != 0) ||
        (info.to == 0 && info.from != 0)) {
        setState(() {
          if (_videoControllers.length > _selectedPage)
            _videoControllers[_selectedPage].update(info);
        });
      }
    });
  }

  List<Widget> getVideos() {
    List<Widget> videos = [];

    for (int video = 0; video < _videoControllers.length; video++) {
      videos.add(VideoScreen(_videoControllers[video]));
    }

    if (_videoControllers.length == 0) {
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
          if (_selectedPage != page) {
            NavInfo info = new NavInfo(
              type: NavInfoType.Video,
              from: _selectedPage,
              to: page
            );
            // TODO: only update where necessary
            for (int video = 0; video < _videoControllers.length; video++) {
              _videoControllers[video].update(info);
            }
          }

          if (_selectedPage > _videoControllers.length - 5) {
            // Load from the server if no unloaded videos are left
            fetchVideos(context).then((videos) {
              setState(() {
                _videoControllers.add(VideoScreenController(
                  index: _videoControllers.length,
                  video: videos[0],
                  callback: () => setState(() {})
                ));
              });
            });
          }

          _selectedPage = page;
        });
      }
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _streamSubscription.cancel();
    super.dispose();
  }
}