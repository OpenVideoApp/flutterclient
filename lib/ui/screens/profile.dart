import 'package:flutter/material.dart';
import 'package:flutterclient/api/user.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/custom_appbar.dart';
import 'package:flutterclient/ui/widget/user_profile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ProfilePage extends StatelessWidget {
  final String username;
  ProfilePage(this.username);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ProfileTab(this.username)
      )
    );
  }
}

class ProfileTab extends StatefulWidget {
  final String username;
  ProfileTab(this.username);

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Container(
      color: theme.backgroundColor,
      alignment: Alignment.center,
      child: Query(
        options: QueryOptions(
          documentNode: gql("""
            query GetUser(\$username: String!) {
              user(name: \$username) {
                ... on User {
                  name
                  displayName
                  profilePicURL
                  following
                  followers
                  likes
                } ... on APIError {error}
              }
            }
          """),
          variables: {
            "username": widget.username
          }
        ),
        builder: (QueryResult result, {VoidCallback refetch, FetchMore fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          } else if (result.loading) {
            return CircularProgressIndicator();
          }

          var userJson = result.data["user"];
          if (userJson["error"] != null) return Text(userJson["error"]);

          var user = User.fromJson(userJson);
          if (user.displayName.length == 0) user.displayName = user.name;

          var outlineColor = Color.fromRGBO(0, 0, 0, 0.5);
          var divider = Divider(
            height: 0.5,
            thickness: 0.5,
            color: outlineColor
          );

          return NotificationListener(
            onNotification: (notification) {
              if (notification is ProfileUpdatedNotification) {
                refetch();
                return true;
              } else return false;
            },
            child: Column(
              children: <Widget>[
                CustomAppBar(
                  title: user.displayName,
                  left: GestureDetector(
                    onTap: () {
                      print("add friends");
                    },
                    child: Icon(
                      Icons.group_add,
                      size: 25,
                      color: theme.textTheme.headline5.color
                    )
                  ),
                  right: GestureDetector(
                    onTap: () {
                      print("special profile button");
                    },
                    child: Icon(
                      FontAwesome.ellipsis_h_regular,
                      size: 25,
                      color: theme.textTheme.headline5.color
                    )
                  )
                ),
                divider,
                UserOverview(
                  user: user
                ),
                Container(
                  padding: EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      BorderedFlatButton(
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        borderColor: outlineColor,
                        width: 150, height: 50,
                        margin: EdgeInsets.all(5),
                        onTap: () {
                          logger.i("Edit Profile");
                        },
                        text: Text(
                          "Edit Profile",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500
                          )
                        )
                      ),
                      BorderedFlatButton(
                        backgroundColor: Colors.white,
                        textColor: Colors.black,
                        borderColor: outlineColor,
                        width: 50, height: 50,
                        margin: EdgeInsets.all(5),
                        onTap: () {
                          logger.i("Favorites");
                        },
                        text: Icon(
                          Icons.star_border,
                          size: 21
                        )
                      )
                    ]
                  )
                ),
                divider
              ]
            )
          );
        }
      )
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}