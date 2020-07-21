import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/logging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

Future<List<Video>> fetchVideos(BuildContext context, {int count = 1}) async {
  QueryResult result = await graphqlClient.value.query(
    QueryOptions(
      documentNode: gql("""
        query GetVideos(\$count: Int) {
          videos(count: \$count) {
            id
            src
            desc
            likes
            comments
            sound {
              user {
                name
              }
              desc
            }
            user {
              name
              profilePicURL
            }
          }
        }
      """),
      fetchPolicy: FetchPolicy.networkOnly,
      variables: {
        "count": count
      }
    )
  );

  if (result.hasException) {
    throw Exception("Failed to get videos: ${result.exception.toString()}");
  }

  var videosJson = result.data["videos"];
  List<Video> videos = [];

  for (int video = 0; video < videosJson.length; video++) {
    videos.add(Video.fromJson(videosJson[video]));
  }

  return videos;
}

class Video {
  String id, src, desc;
  int likes, shares, comments;
  bool liked;
  Sound sound;
  User user;
  VoidCallback likeCallback;

  Video({this.id, this.src, this.desc, this.likes, this.shares, this.comments, this.liked, this.sound, this.user});

  factory Video.fromJson(Map<String, dynamic> json) {
    return new Video(
      id: json["id"],
      src: json["src"],
      desc: json["desc"],
      likes: json["likes"],
      shares: 0,
      comments: json["comments"],
      liked: false,
      sound: Sound.fromJson(json["sound"]),
      user: User.fromJson(json["user"])
    );
  }

  void setLiked(liked) {
    if (liked != this.liked) {
      graphqlClient.value.mutate(MutationOptions(
        documentNode: gql("""
          mutation LikeVideo(\$videoId: String!, \$remove: Boolean!) {
            likeVideo(videoId: \$videoId, remove: \$remove) {
              ... on APIResult {success}
              ... on APIError {error}
            }
          }
        """),
        variables: {
          "videoId": id,
          "remove": !liked
        }
      )).then((result) {
        var like = result.data["likeVideo"];
        if (like["error"] != null) logger.w("Failed to like video:", like["error"]);
        else if (like["success"]) logger.i("${liked ? "L" : "Unl"}iked video #$id");
        else logger.i("Liking/Disliking video #$id had no effect");
      });
    }
    this.liked = liked;
    if (likeCallback != null) {
      likeCallback();
    }
  }
}

class Sound {
  String desc;
  User user;

  Sound({this.desc, this.user});

  factory Sound.fromJson(Map<String, dynamic> json) {
    return new Sound(
      desc: json["desc"],
      user: User.fromJson(json["user"])
    );
  }
}

class User {
  String name;
  String displayName;
  String profilePicURL;

  User({this.name, this.displayName, this.profilePicURL});

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
      name: json["name"],
      displayName: json["displayName"],
      profilePicURL: json["profilePicURL"]
    );
  }
}