import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/user.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class UserListItem extends StatelessWidget {
  final User user;

  UserListItem(this.user);

  @override
  Widget build(BuildContext context) {
    var themeColor = Theme.of(context).textTheme.bodyText1.color;
    return Container(
      padding: EdgeInsets.fromLTRB(5, 10, 5, 10),
      child: DefaultTextStyle(
        style: TextStyle(
          color: themeColor,
          fontSize: 15
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
              child: UserProfileIcon(
                user: this.user,
                size: 40
              )
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "@" + this.user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w500
                  )
                ),
                Text(this.user.displayName)
              ]
            )
          ]
        )
      )
    );
  }
}

class UserList extends StatelessWidget {
  final bool following;
  final User user;

  UserList({@required this.user, this.following = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Query(
          options: QueryOptions(
            documentNode: gql("""
              query GetUsers(\$username: String!) {
                users: ${following ? "following" : "followers"}(name: \$username) {
                  name
                  displayName
                  profilePicURL
                }
              }
            """),
            variables: {
              "username": this.user.name
            }
          ),
          builder: (result, {refetch, fetchMore}) {
            if (result.hasException) {
              return Center(child: Text(result.exception.toString()));
            } else if (result.loading) {
              return Center(child: CircularProgressIndicator());
            }
            var followers = result.data["users"];
            return ListView.builder(
              itemCount: followers.length,
              itemBuilder: (context, index) {
                User follower = User.fromJson(followers[index]);
                return UserListItem(follower);
              }
            );
          }
        )
      ),
      appBar: AppBar(
        title: Text(following ? "Following" : "Followers")
      ),
    );
  }
}

class ProfileStatButton extends StatelessWidget {
  final VoidCallback onTap;
  final String value, type;

  ProfileStatButton({this.onTap, this.value, this.type});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: this.onTap,
      child: Container(
        color: Colors.white,
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                this.value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold
                )
              )
            ),
            Text(
              this.type,
              style: TextStyle(
                fontSize: 15
              )
            )
          ]
        )
      )
    );
  }
}

class UserOverview extends StatelessWidget {
  final User user;

  UserOverview({@required this.user});

  PageRouteBuilder _userListRoute({bool following = false}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) {
        return UserList(
          user: user,
          following: following
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var tween = Tween(
          begin: 0.0,
          end: 1.0
        );
        var anim = animation.drive(tween);
        return ScaleTransition(
          scale: anim,
          child: child
        );
      },
      transitionDuration: Duration(milliseconds: 100)
    );
  }

  @override
  Widget build(BuildContext context) {
    var verticalDivider = VerticalDivider(
      thickness: 0.7,
      width: 35,
      color: Color.fromRGBO(0, 0, 0, 0.5),
      indent: 15,
      endIndent: 15
    );

    return Container(
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: UserProfileIcon(
              user: user,
              size: 125
            )
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              "@${user.name}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500
              )
            )
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ProfileStatButton(
                    onTap: () {
                      Navigator.of(context).push(_userListRoute(
                        following: true
                      ));
                    },
                    value: compactInt(user.following),
                    type: "Following"
                  ),
                  verticalDivider,
                  ProfileStatButton(
                    onTap: () {
                      Navigator.of(context).push(_userListRoute(
                        following: false
                      ));
                    },
                    value: compactInt(user.followers),
                    type: "Followers"
                  ),
                  verticalDivider,
                  ProfileStatButton(
                    onTap: () {
                      logger.i("Tapped Likes");
                    },
                    value: compactInt(user.likes),
                    type: "Likes"
                  )
                ]
              )
            )
          )
        ]
      )
    );
  }
}

class UserProfileIcon extends StatelessWidget {
  final User user;
  final double size;

  UserProfileIcon({@required this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: this.size,
      height: this.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(255, 238, 242, 228),
        border: Border.all(
          color: Colors.grey,
          width: 1
        ),
        image: DecorationImage(
          fit: BoxFit.fill,
          image: NetworkImage(this.user.profilePicURL)
        )
      )
    );
  }
}