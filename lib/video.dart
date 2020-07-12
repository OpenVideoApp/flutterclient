import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

Future<Video> getVideo() async {
  http.Response response = await http.post(
    "http://192.168.0.220:3000/video",
    headers: <String, String>{
      "Content-Type": "application/json; charset=UTF-8"
    },
    body: jsonEncode(<String, dynamic>{
      "test": "hello world",
      "count": 37
    })
  );

  if (response.statusCode == 201) {
    return Video.fromJson(json.decode(response.body));
  } else {
    throw Exception("Failed to get video (response code ${response.statusCode})");
  }
}

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
    this.comments = comments;
    this.liked = liked == null ? false : liked;
    this.sound = sound;
  }

  factory Video.fromJson(Map<String, dynamic> json) {
    return new Video(
      src: json["src"],
      desc: json["desc"],
      likes: json["likes"],
      shares: json["shares"],
      comments: json["comments"],
      liked: json["liked"],
      sound: new Sound(json["sound"]["desc"])
    );
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