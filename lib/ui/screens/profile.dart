import 'package:flutter/material.dart';
import 'package:flutterclient/api/user.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:flutterclient/ui/widget/user_profile.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ProfileTab extends StatefulWidget {
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
            query GetUser {
              me {
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
          """)
        ),
        builder: (QueryResult result, {VoidCallback refetch, FetchMore fetchMore}) {
          if (result.hasException) {
            return Text(result.exception.toString());
          } else if (result.loading) {
            return CircularProgressIndicator();
          }

          var me = result.data["me"];
          if (me["error"] != null) return Text(me["error"]);

          var user = User.fromJson(me);
          if (user.displayName.length == 0) user.displayName = user.name;

          var divider = Divider(
            height: 0.5,
            thickness: 0.5,
            color: Color.fromRGBO(0, 0, 0, 0.5)
          );

          return Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        print("add friends");
                      },
                      onTapDown: (_) {
                        print("tap down");
                      },
                      onTapCancel: () {
                        print("tap cancel");
                      },
                      child: Icon(
                        Icons.group_add,
                        size: 25,
                        color: theme.textTheme.headline5.color
                      )
                    ),
                    Text(
                      user.displayName,
                      style: theme.textTheme.headline5.copyWith(
                        fontWeight: FontWeight.bold
                      )
                    ),
                    GestureDetector(
                      onTap: () {
                        print("special profile button");
                      },
                      child: Icon(
                        FontAwesome.ellipsis_h_regular,
                        size: 25,
                        color: theme.textTheme.headline5.color
                      )
                    )
                  ]
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
                      borderColor: Color.fromRGBO(0, 0, 0, 0.25),
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
                      borderColor: Color.fromRGBO(0, 0, 0, 0.25),
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