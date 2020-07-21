import 'dart:io' show Platform;
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoggedInNotification extends Notification {}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usernameController;
  TextEditingController _passwordController;

  FocusNode _passwordFocus = FocusNode();
  bool _passwordVisible = false;
  bool _passwordSelected = false;

  String error;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    _passwordFocus.addListener(() {
      setState(() {
        _passwordSelected = _passwordFocus.hasFocus;
      });
    });
  }

  void signup() async {
    logger.i("Creating Account...");
    QueryResult result = await graphqlClient.value.mutate(
      MutationOptions(
        documentNode: gql("""
          mutation CreateUser(\$name: String!, \$password: String!, \$displayName: String!, \$profilePicURL: String!) {
            createUser(
              name: \$name, 
              password: \$password, 
              displayName: \$displayName, 
              profilePicURL: \$profilePicURL
            ) {
              ... on User {
                name
                createdAt
              } ... on APIError {error}
            }
          }
        """),
        fetchPolicy: FetchPolicy.networkOnly,
        variables: {
          "name": _usernameController.text,
          "password": _passwordController.text,
          "displayName": "Unnamed User",
          "profilePicURL": "${_usernameController.text}.jpg"
        }
      )
    );

    if (result.hasException) {
      throw Exception("Failed to create account: ${result.exception
        .toString()}");
    }

    var user = result.data["createUser"];
    logger.i("Created User: $user");

    setState(() {
      this.error = user["error"];
    });
  }

  Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.product}";
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      // TODO: correctly label ios devices
      return iosInfo.localizedModel;
    } else
      return "Desktop";
  }

  void signin() async {
    logger.i("Signing in..");

    var device = await getDeviceName();
    var username = _usernameController.text;

    QueryResult result = await graphqlClient.value.mutate(
      MutationOptions(
        documentNode: gql("""
          mutation Login(
            \$username: String!,
            \$password: String!,
            \$device: String!
          ) {
            login(username: \$username, password: \$password, device: \$device) {
              ... on Login {token}
              ... on APIError {error}
            }
          }
        """),
        fetchPolicy: FetchPolicy.networkOnly,
        variables: {
          "username": username,
          "password": _passwordController.text,
          "device": device
        }
      )
    );

    _passwordController.clear();

    if (result.hasException) {
      logger.e("Failed to sign in: ${result.exception}");
      return setState(() {
        this.error = "Unexpected Error";
      });
    }

    var login = result.data["login"];
    logger.i("Login: $login}");

    if (login["error"] != null) {
      return setState(() {
        this.error = login["error"];
      });
    }

    var prefs = await SharedPreferences.getInstance();
    var token = login["token"];

    prefs.setString("username", username).then((_) {
      prefs.setString("token", token);
    });

    AuthInfo.instance().set(username, token);
    new LoggedInNotification().dispatch(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        alignment: Alignment.center,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(15),
                child: Text(
                  "OpenVideo",
                  style: Theme
                    .of(context)
                    .textTheme
                    .headline4
                )
              ),
              if (this.error != null) Padding(
                padding: EdgeInsets.all(10),
                child: Text(
                  this.error,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 15
                  )
                )
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: "Username",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)
                    )
                  ),
                )
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  focusNode: _passwordFocus,
                  decoration: InputDecoration(
                    hintText: "Password",
                    suffixIcon: !_passwordSelected ? null : GestureDetector(
                      onTap: () {
                        setState(() {
                          _passwordVisible = !_passwordVisible;
                        });
                      },
                      child: Icon(
                        _passwordVisible ? FontAwesome
                          .eye_slash_solid : FontAwesome.eye_solid,
                        size: 20
                      )
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)
                    )
                  ),
                )
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: RaisedButton(
                      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                      onPressed: () => signin(),
                      child: Text("Login")
                    )
                  ),
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: RaisedButton(
                      padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                      onPressed: () => signup(),
                      child: Text("Create Account")
                    )
                  )
                ]
              )
            ]
          )
        )
      )
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}