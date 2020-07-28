import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/video/components.dart';
import 'package:flutterclient/ui/widget/video/controller.dart';
import 'package:flutterclient/ui/widget/video/screen.dart';
import 'package:flutterclient/ui/widget/comments_popup.dart';

class HomeTab extends StatefulWidget {
  final Stream<NavInfo> shouldTriggerChange;

  HomeTab({@required this.shouldTriggerChange});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  StreamController<VideoNavInfo> _changeNotifier = new StreamController.broadcast();
  StreamSubscription<NavInfo> _streamSubscription;
  List<Video> _videos = [];
  Map<int, VideoScreenController> _videoControllers = {};
  PageController _pageController;
  int _selectedPage = 0;
  bool _commentsVisible = false;

  @override
  void initState() {
    super.initState();

    fetchVideos(context, count: 5).then((videos) {
      setState(() {
        _videos.addAll(videos);
      });
    });

    _pageController = PageController();

    _streamSubscription = widget.shouldTriggerChange.listen((info) {
      _changeNotifier.add(VideoNavInfo(
        type: info.type,
        from: info.from,
        to: info.to,
        selectedVideo: _selectedPage,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener(
      onNotification: (notification) {
        if (notification is CommentsPopupNotification) {
          setState(() {
            _commentsVisible = notification.visible;
          });
          return true;
        }
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemBuilder: (context, index) {
          if (index >= _videos.length) {
            return EmptyVideo();
          }
          var controller = getVideoController(index);
          return VideoScreen(
            controller: controller,
            notifier: _changeNotifier.stream,
            index: index,
          );
        },
        itemCount: _videos.length,
        physics: _commentsVisible ? NeverScrollableScrollPhysics() : PageScrollPhysics(),
        onPageChanged: (page) {
          logger.i("Selected page $page");
          _changeNotifier.sink.add(VideoNavInfo(
            type: NavInfoType.Video,
            from: _selectedPage,
            to: page,
            selectedVideo: page,
          ));

          _selectedPage = page;

          // Copy key set to avoid concurrent modification issues
          var controllerKeys = _videoControllers.keys.toList();

          for (var key in controllerKeys) {
            var distance = (key - _selectedPage).abs();
            if (distance > 5) {
              logger.i("Removing video screen controller #$key with distance $distance");
              _videoControllers[key].dispose();
              _videoControllers.remove(key);
            }
          }

          // Ensure there are some videos pre-loaded in a range around the selected page
          for (var i = _selectedPage - 2; i < _selectedPage + 3; i++) {
            if (i < 0 || i >= _videos.length) {
              continue;
            }
            getVideoController(i);
          }

          if (_selectedPage > _videos.length - 5) {
            // Load from the server if no unloaded videos are left
            fetchVideos(context).then((videos) {
              setState(() {
                _videos.addAll(videos);
              });
            });
          }
        },
      ),
    );
  }

  VideoScreenController getVideoController(int index) {
    return _videoControllers.putIfAbsent(index, () {
      logger.i("Creating video screen controller #$index");
      return VideoScreenController(index: index, video: _videos[index]);
    });
  }

  @override
  void dispose() {
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    _streamSubscription.cancel();
    _changeNotifier.close();
    super.dispose();
  }
}
