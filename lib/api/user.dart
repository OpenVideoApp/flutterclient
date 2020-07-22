import 'package:flutter/material.dart';

class User {
  String name, displayName, profilePicURL;
  int likes;

  User({this.name, this.displayName, this.profilePicURL, this.likes});

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
      name: json["name"],
      displayName: json["displayName"],
      profilePicURL: json["profilePicURL"],
      likes: json["likes"]
    );
  }

  Widget createIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(255, 238, 242, 228),
        border: Border.all(
          color: Colors.grey,
          width: 1
        ),
        image: DecorationImage(
          fit: BoxFit.fill,
          image: NetworkImage(this.profilePicURL)
        )
      )
    );
  }
}