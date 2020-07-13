import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/tabs/video_screen.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:http/http.dart' as http;

String videoQuery = """
  query GetVideos(\$count: Int!) {
    videos(count: \$count) {
      src
      desc
    }
  }
""";

// TODO: make this work or just use http
Query fetchVideo() {
  return Query(
    options: QueryOptions(
      documentNode: gql(videoQuery),
      variables: {
        "count": 3
      }
    ),
    builder: (QueryResult result, {VoidCallback refetch, FetchMore fetchMore}) {
      if (result.hasException) {
        return Container(
          alignment: Alignment.center,
          child: Text(result.exception.toString())
        );
      } else if (result.loading) {
        return makeEmptyVideo();
      }

      Video video = Video.fromJson(result.data["videos"][0]);

      return Container(
        alignment: Alignment.center,
        child: Text(video.desc)
      );
    }
  );
}

Future<List<Video>> fetchVideos({int count = 1}) async {
  http.Response response = await http.post(
    "https://7jqrk8zydc.execute-api.ap-southeast-2.amazonaws.com/Prod/graphql",
    headers: <String, String>{
      "Content-Type": "application/json; charset=UTF-8"
    },
    body: """
      {
        videos(count: $count) {
          src
          desc
          likes
          comments
          shares
          liked
          sound {
            desc
          }
        }
      }
    """
  );

  if (response.statusCode == 201) {
    var videosJson = json.decode(response.body)["data"]["videos"];
    List<Video> videos = [];
    for (int video = 0; video < videosJson.length; video++) {
      videos.add(Video.fromJson(videosJson[video]));
    }
    return videos;
  } else {
    throw Exception("Failed to get videos (response code ${response.statusCode})");
  }
}

class Video {
  String src, desc;
  int likes, shares, comments;
  bool liked;
  Sound sound;

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
}

class Sound {
  String desc;

  Sound(String desc) {
    this.desc = desc;
  }
}