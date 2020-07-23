import 'package:flutterclient/api/apihelpers.dart';

class User {
  String name, displayName, profilePicURL;
  int following, followers, likes;
  bool followsYou, followedByYou;

  User({
    this.name, this.displayName, this.profilePicURL,
    this.following, this.followers, this.likes,
    this.followsYou, this.followedByYou
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
      name: json["name"],
      displayName: json["displayName"],
      profilePicURL: json["profilePicURL"],
      following: json["following"],
      followers: json["followers"],
      likes: json["likes"],
      followsYou: getOptionalBool(json, "followsYou"),
      followedByYou: getOptionalBool(json, "followedByYou")
    );
  }
}