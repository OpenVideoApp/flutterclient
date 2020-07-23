import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/ui/screens/login.dart';
import 'package:flutterclient/ui/screens/main.dart';
import 'package:flutterclient/ui/themes.dart';
import 'package:flutterclient/logging.dart';

void main() {
  runApp(OpenVideoApp());
}

class OpenVideoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GraphQLProvider(
      client: graphqlClient,
      child: MaterialApp(
        title: "OpenVideo",
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        themeMode: ThemeMode.light,
        home: OpenVideoScreen(),
      ),
    );
  }
}

class OpenVideoScreen extends StatefulWidget {
  _OpenVideoScreen createState() => _OpenVideoScreen();
}

class _OpenVideoScreen extends State<OpenVideoScreen> {
  bool loading = true;
  bool loggedIn = false;

  @override
  void initState() {
    super.initState();

    if (!loggedIn) {
      SharedPreferences.getInstance().then((prefs) {
        if (prefs.containsKey("username")) {
          var username = prefs.getString("username");
          var token = prefs.getString("token");
          AuthInfo.instance().set(username, token);

          graphqlClient.value
              .query(
            QueryOptions(documentNode: gql("""
                query ValidateLogin() {
                  me {
                    ... on User {
                      displayName
                    } ... on APIError {error}
                  }
                }
              """), fetchPolicy: FetchPolicy.networkOnly),
          )
              .then((result) {
            if (result.hasException) {
              setState(() {
                loading = false;
              });
              return logger.e("Failed to validate login: ${result.exception}");
            }
            var user = result.data["me"];
            if (user["error"] != null) {
              logger.w("Invalid login: ${user["error"]}");
              prefs.remove("username").then((_) {
                prefs.remove("password");
              });
              AuthInfo.instance().set(null, null);
              setState(() {
                loading = false;
              });
            } else {
              logger.i("Logged in as ${user["displayName"]}");
              setState(() {
                loading = false;
                loggedIn = true;
              });
            }
          });
        } else {
          setState(() {
            loading = false;
          });
        }
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          "OpenVideo",
          style: Theme.of(context).textTheme.headline3,
        ),
      );
    if (loggedIn) {
      return MainScreen();
    } else {
      return NotificationListener(
        child: LoginScreen(),
        onNotification: (notification) {
          if (notification is LoggedInNotification) {
            setState(() {
              loggedIn = true;
            });
            return true;
          }
          return false;
        },
      );
    }
  }
}
