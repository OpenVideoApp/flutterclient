import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/api/user.dart';
import 'package:flutterclient/api/video.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/screens/profile.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/buttons.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ProfileUpdatedNotification extends Notification {}

class ProfileScreenNotification extends Notification {
  final bool opened;

  ProfileScreenNotification({this.opened = true});
}

class VideoPreview extends StatefulWidget {
  final Video video;

  VideoPreview(this.video);

  _VideoPreviewState createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image(
          fit: BoxFit.fitWidth,
          image: NetworkImage(widget.video.previewSrc),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          child: Padding(
            padding: EdgeInsets.all(5),
            child: Row(
              children: <Widget>[
                Icon(
                  FontAwesome.eye_solid,
                  size: 13,
                  color: Colors.white,
                ),
                SizedBox(width: 5),
                Text(
                  compactInt(widget.video.views),
                  style: TextStyle(
                    color: Colors.white,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FollowButton extends StatefulWidget {
  final User user;
  final double width, height, fontSize;

  FollowButton(this.user, {this.width = 100, this.height = 35, this.fontSize = 15});

  _FollowButtonState createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  @override
  Widget build(BuildContext context) {
    bool following = widget.user.followedByYou;
    return BorderedFlatButton(
      onTap: () {
        setState(() {
          widget.user.followedByYou = !following;
        });

        var who = widget.user.name;

        graphqlClient.value
            .mutate(MutationOptions(
          documentNode: gql("""
            mutation FollowUser(\$username: String!, \$remove: Boolean) {
              followUser(username: \$username, remove: \$remove) {
                ... on APIResult {success}
                ... on APIError {error}
              }
            }
          """),
          variables: {
            "username": widget.user.name,
            "remove": following,
          },
        ))
            .then((result) {
          if (result.hasException) return logger.w("Failed to change following for '$who': ${result.exception}");
          var res = result.data["followUser"];
          if (res["error"] != null) return logger.w("Failed to change following for '$who': ${res["error"]}");
          logger.i("${following ? "Unf" : "F"}ollowed '$who'!");
          new ProfileUpdatedNotification().dispatch(context);
        });
      },
      text: Text(
        following ? "Following" : "Follow",
        style: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: widget.fontSize,
          color: following ? Colors.black : Colors.white,
        ),
      ),
      backgroundColor: following ? Colors.white : Colors.pinkAccent,
      borderColor: Color.fromRGBO(0, 0, 0, 0.5),
      width: widget.width,
      height: widget.height,
      margin: EdgeInsets.only(left: 5, right: 5),
    );
  }
}

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
          fontSize: 15,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(5, 5, 10, 5),
              child: UserProfileIcon(
                user: this.user,
                size: 40,
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "@" + this.user.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(this.user.displayName),
                ],
              ),
            ),
            if (this.user.name != AuthInfo.instance().username) FollowButton(this.user)
          ],
        ),
      ),
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
                  followedByYou
                }
              }
            """),
            variables: {
              "username": this.user.name,
            },
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
              },
            );
          },
        ),
      ),
      appBar: AppBar(
        title: Text(following ? "Following" : "Followers"),
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              this.type,
              style: TextStyle(
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserOverview extends StatelessWidget {
  final User user;

  UserOverview({@required this.user});

  PageRouteBuilder _userListRoute({bool following = false}) {
    return zoomTo((context, animation, secondaryAnimation) {
      return UserList(
        user: this.user,
        following: following,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var verticalDivider = VerticalDivider(
      thickness: 0.7,
      width: 35,
      color: Color.fromRGBO(0, 0, 0, 0.5),
      indent: 15,
      endIndent: 15,
    );

    return Container(
      child: Column(
        children: <Widget>[
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(10),
            child: UserProfileIcon(
              user: this.user,
              size: 125,
              linkProfile: false,
            ),
          ),
          Padding(
            padding: EdgeInsets.all(5),
            child: Text(
              "@${this.user.name}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.all(15),
            child: IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ProfileStatButton(
                      onTap: () {
                        Navigator.of(context)
                            .push(_userListRoute(
                          following: true,
                        ))
                            .then((_) {
                          /*
                          [ERROR:flutter/lib/ui/ui_dart_state.cc(157)] Unhandled Exception: Looking up a deactivated widget's ancestor is unsafe.
                          At this point the state of the widget's element tree is no longer stable.
                          To safely refer to a widget's ancestor in its dispose() method, save a reference to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's didChangeDependencies() method.
                         */
                          new ProfileUpdatedNotification().dispatch(context);
                        });
                      },
                      value: compactInt(this.user.following),
                      type: "Following"),
                  verticalDivider,
                  ProfileStatButton(
                    onTap: () {
                      Navigator.of(context).push(_userListRoute(following: false)).then((_) {
                        new ProfileUpdatedNotification().dispatch(context);
                      });
                    },
                    value: compactInt(this.user.followers),
                    type: this.user.followers == 1 ? "Follower" : "Followers",
                  ),
                  verticalDivider,
                  ProfileStatButton(
                    onTap: () {
                      logger.i("Tapped Likes");
                    },
                    value: compactInt(this.user.likes),
                    type: this.user.likes == 1 ? "Like" : "Likes",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UserProfileIcon extends StatelessWidget {
  final User user;
  final double size;
  final bool linkProfile;
  final VoidCallback onPressed;

  UserProfileIcon({
    @required this.user,
    this.size = 40,
    this.linkProfile = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (this.linkProfile) {
          new ProfileScreenNotification(opened: true).dispatch(context);
          Navigator.of(context).push(zoomTo((context, anim, secondAnim) {
            return ProfilePage(this.user.name);
          })).then((_) {
            new ProfileScreenNotification(opened: false).dispatch(context);
          });
        } else if (this.onPressed != null) this.onPressed();
      },
      child: Container(
        width: this.size,
        height: this.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color.fromARGB(255, 238, 242, 228),
          border: Border.all(
            color: Colors.grey,
            width: 1,
          ),
          image: DecorationImage(
            fit: BoxFit.fill,
            image: NetworkImage(this.user.profilePicURL),
          ),
        ),
      ),
    );
  }
}
