import 'package:flutter/material.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
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
                name
                displayName
                profilePicture
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

          return Stack(
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
                      result.data["me"]["displayName"],
                      style: theme.textTheme.headline5
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
              Container(
                alignment: Alignment.center,
                child: Text(result.data.toString())
              )
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