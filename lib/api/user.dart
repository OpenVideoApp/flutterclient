import 'package:flutterclient/api/apihelpers.dart';
import 'package:flutterclient/api/video.dart';

class User {
  String name, displayName, profilePicURL;
  List<Video> videos;
  int following, followers, likes;
  bool followsYou, followedByYou;

  User({
    this.name,
    this.displayName,
    this.profilePicURL,
    List<dynamic> videos,
    this.following,
    this.followers,
    this.likes,
    this.followsYou,
    this.followedByYou,
  }) {
    this.videos = [];
    if (videos != null) {
      for (var video in videos) {
        this.videos.add(Video.fromJson(video));
      }
    }

  }

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
      name: json["name"],
      displayName: json["displayName"],
      profilePicURL: json["profilePicURL"],
      videos: json["videos"],
      following: getOptionalInt(json, "following"),
      followers: getOptionalInt(json, "followers"),
      likes: getOptionalInt(json, "likes"),
      followsYou: getOptionalBool(json, "followsYou"),
      followedByYou: getOptionalBool(json, "followedByYou"),
    );
  }
}
