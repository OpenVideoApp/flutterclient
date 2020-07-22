class User {
  String name, displayName, profilePicURL;
  int following, followers, likes;

  User({
    this.name, this.displayName, this.profilePicURL,
    this.following, this.followers, this.likes
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return new User(
      name: json["name"],
      displayName: json["displayName"],
      profilePicURL: json["profilePicURL"],
      following: json["following"],
      followers: json["followers"],
      likes: json["likes"]
    );
  }
}