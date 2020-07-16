import 'package:flutter/material.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/main.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

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
              success
              error
            }
          }
        """),
        fetchPolicy: FetchPolicy.networkOnly,
        variables: {
          "name": _usernameController.text,
          "password": _passwordController.text,
          "displayName": "Raph Hennessy",
          "profilePicURL": "https://open-video.s3-ap-southeast-2.amazonaws.com/raphydaphy.jpg"
        }
      )
    );

    if (result.hasException) {
      throw Exception("Failed to create account: ${result.exception.toString()}");
    }

    logger.i("Got response ${result.data}");
  }

  void signin() async {
    logger.i("Signing in..");
    QueryResult result = await graphqlClient.value.query(
      QueryOptions(
        documentNode: gql("""
          query GetUser(\$name: String!) {
            user(name: \$name) {
              name
              displayName
              profilePicture
            }
          }
        """),
        fetchPolicy: FetchPolicy.networkOnly,
        variables: {
          "name": _usernameController.text
        }
      )
    );

    if (result.hasException) {
      logger.e("Failed to sign in: ${result.exception}");
    }

    logger.i("Got response ${result.data}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                        _passwordVisible ? FontAwesome.eye_slash_solid : FontAwesome.eye_solid,
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