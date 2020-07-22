import 'package:flutter/material.dart';
import 'package:flutterclient/api/user.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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

          var dividerColor = Color.fromRGBO(0, 0, 0, 0.5);

          var divider = Divider(
            height: 0.5,
            thickness: 0.5,
            color: dividerColor
          );

          var verticalDivider = VerticalDivider(
            thickness: 0.7,
            width: 35,
            color: dividerColor,
            indent: 15,
            endIndent: 15
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
              Container(
                alignment: Alignment.center,
                padding: EdgeInsets.all(10),
                child: user.createIcon(125)
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: Text(
                  "@${user.name}",
                  style: theme.textTheme.headline6.copyWith(
                    fontWeight: FontWeight.bold
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
                          logger.i("Tapped Following");
                        },
                        value: compactInt(126),
                        type: "Following"
                      ),
                      verticalDivider,
                      ProfileStatButton(
                        onTap: () {
                          logger.i("Tapped Followers");
                        },
                        value: compactInt(1834),
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