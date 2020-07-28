import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/logging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:video_player/video_player.dart';

class VideoScreenController {
  final int index;
  final Video video;

  VideoPlayerController _controller;
  Future<void> future;

  bool ready = false, paused;

  DateTime startedPlayingAt;
  int secondsWatched = 0;

  VideoScreenController({@required this.index, @required this.video, this.paused = false}) {
    future = this.video.getFile().then((file) {
      _controller = VideoPlayerController.file(file);
      return _controller.initialize().then((_) {
        _controller.setLooping(true);
        ready = true;
      });
    });
  }

  bool isPlaying() {
    return ready ? _controller.value.isPlaying : false;
  }

  void toggle() {
    if (isPlaying()) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (ready) {
      logger.i("Playing video #$index");
      _controller.play();
      paused = false;
      startedPlayingAt = DateTime.now();
    } else {
      logger.w("Tried to play video $index before it had loaded");
    }
  }

  void pause({bool forced = false}) {
    if (ready) {
      logger.i("Paused video #$index");
      _controller.pause();
      if (startedPlayingAt != null) {
        secondsWatched += DateTime.now().difference(startedPlayingAt).inSeconds;
      }
      if (!forced) paused = true;
    }
  }

  Future<void> restart() {
    return _controller.seekTo(Duration.zero);
  }

  VideoPlayerController get controller {
    return _controller;
  }

  VideoPlayerValue get value {
    return _controller == null ? null : _controller.value;
  }

  double get aspectRatio {
    return ready ? _controller.value.aspectRatio : 1.8;
  }

  Future<double> get progress async {
    if (ready) {
      var position = await _controller.position;
      var duration = _controller.value.duration.inMilliseconds.toDouble();
      return position.inMilliseconds.toDouble() / duration;
    } else {
      return 0;
    }
  }

  void dispose() {
    //pause(forced: true);
    //restart();

    _controller?.dispose();

    graphqlClient.value
        .mutate(MutationOptions(
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
        "seconds": secondsWatched,
      },
    ))
        .then((result) {
      var watch = result.data["watchVideo"];
      if (watch["error"] != null) {
        logger.w("Failed to add watch data:", watch["error"]);
      } else {
        logger.i("Added watch data to video '${video.id}', bring total time to ${watch["seconds"]} seconds");
      }
    });
    secondsWatched = 0;
  }
}
