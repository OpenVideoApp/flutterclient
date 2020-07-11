import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';

class Video {
  String src, desc;
  int likes, shares, comments;
  bool liked;
  Sound sound;
  VideoPlayerController controller;
  Future<void> controllerFuture;
  ScrollController soundScrollController;

  Video({String src, String desc, int likes, int shares, int comments, bool liked, Sound sound}) {
    this.src = src;
    this.desc = desc;
    this.likes = likes;
    this.shares = shares;
    this.liked = liked == null ? false : liked;
    this.comments = comments;
    this.sound = sound;
  }

  void initControllers(listener) {
    this.controller = new VideoPlayerController.network(this.src)
      ..setLooping(true)
      ..addListener(listener);
    this.controllerFuture = this.controller.initialize();
    this.soundScrollController = new ScrollController();
  }
}

class Sound {
  String desc;

  Sound(String desc) {
    this.desc = desc;
  }
}