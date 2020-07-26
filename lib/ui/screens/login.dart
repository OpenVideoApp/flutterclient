import 'dart:io' show Platform;
import 'package:device_info/device_info.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/api/auth.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/logging.dart';
import 'package:flutterclient/ui/screens/main.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _googleSignIn = GoogleSignIn(
  clientId: "com.googleusercontent.apps.859725405396-fn77ecqnl8bqn1p24ptktokqpv0us32o",
  scopes: [
    "email",
  ],
);

class InitialLoginScreen extends StatefulWidget {
  @override
  _InitialLoginScreenState createState() => _InitialLoginScreenState();
}

class _InitialLoginScreenState extends State<InitialLoginScreen> {
  TextEditingController _usernameController;
  TextEditingController _passwordController;

  FocusNode _passwordFocus = FocusNode();
  bool _passwordVisible = false;
  bool _passwordSelected = false;

  String _usernameError;
  String _passwordError;

  bool _hasAccount = false;
  bool _processing = false;
  String _error;

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

  Future<String> getDeviceName() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return "${androidInfo.manufacturer} ${androidInfo.product}";
    } else if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.name;
    } else {
      return "Desktop";
    }
  }

  bool validateInputs({bool forSignup = false}) {
    var username = _usernameController.text;
    var password = _passwordController.text;

    if (username.length < 3) {
      _usernameError = forSignup ? "Username must be at least 3 characters" : "Invalid Username";
    } else if (username.contains(" ")) {
      _usernameError = forSignup ? "Username cannot contain spaces" : "Invalid Username";
    } else {
      _usernameError = null;
    }

    if (password.length < 8) {
      _passwordError = forSignup ? "Password must be at least 8 characters" : "Invalid Password";
    } else {
      _passwordError = null;
    }

    _error = null;

    if (_usernameError != null || _passwordError != null) {
      setState(() {
        _passwordController.clear();
      });
      return false;
    } else {
      setState(() {
        _processing = true;
      });
      return true;
    }
  }

  void createAccount() async {
    if (!validateInputs(forSignup: true)) return;

    logger.i("Creating Account...");
    QueryResult result = await graphqlClient.value.mutate(MutationOptions(
      documentNode: gql("""
          mutation CreateUser(\$name: String!, \$password: String!, \$device: String!) {
            login: createUser(
              name: \$name, 
              password: \$password, 
              device: \$device
            ) {
              ... on Login {token user {name}}
              ... on LoginError {error forUsername forPassword}
            }
          }
        """),
      fetchPolicy: FetchPolicy.networkOnly,
      variables: {
        "name": _usernameController.text,
        "password": _passwordController.text,
        "device": await getDeviceName(),
      },
    ));

    finishLoginQuery(result);
  }


  void signIn() async {
    if (!validateInputs()) return;

    var device = await getDeviceName();
    var username = _usernameController.text;

    QueryResult result = await graphqlClient.value.mutate(MutationOptions(
      documentNode: gql("""
          mutation Login(
            \$username: String!,
            \$password: String!,
            \$device: String!
          ) {
            login(username: \$username, password: \$password, device: \$device) {
              ... on Login {token user {name}}
              ... on LoginError {error forUsername forPassword}
            }
          }
        """),
      fetchPolicy: FetchPolicy.networkOnly,
      variables: {
        "username": username,
        "password": _passwordController.text,
        "device": device,
      },
    ));

    finishLoginQuery(result);
  }

  void finishLoginQuery(QueryResult res) async {
    _passwordController.clear();

    if (res.hasException) {
      logger.w("Failed to run login/user creation query: ${res.exception}");
      setState(() {
        _error = "An error occurred";
        _processing = false;
      });
      return;
    }

    var login = res.data["login"];
    logger.i("Login Query: $login");

    var loginError = login["error"];

    setState(() {
      if (login["forUsername"] == true) {
        _usernameError = loginError;
      } else if (login["forPassword"] == true) {
        _passwordError = loginError;
      } else {
        _error = loginError;
      }
      _processing = false;
    });

    if (loginError != null) return;

    var accUsername = login["user"]["name"];
    var accToken = login["token"];

    var prefs = await SharedPreferences.getInstance();

    prefs.setString("username", accUsername).then((_) {
      prefs.setString("token", accToken);
    });

    AuthInfo.instance().set(accUsername, accToken);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }


  void googleSignIn() async {
    logger.i("Signing in with Google...");

    try {
      var acc = await _googleSignIn.signIn();
      var auth = await acc.authentication;

      QueryResult result = await graphqlClient.value.mutate(MutationOptions(
        documentNode: gql("""
          mutation LoginWithGoogle(\$idToken: String!) {
            loginWithGoogle(idToken: \$idToken) {
              ... on APIResult {success}
              ... on APIError {error}
            }
          }
        """),
        fetchPolicy: FetchPolicy.networkOnly,
        variables: {"idToken": auth.idToken},
      ));

      if (result.hasException) {
        logger.e("Failed to sign in with google: ${result.exception}");
        return setState(() {
          _error = "Google Sign-In Failed";
        });
      }

      var signin = result.data["loginWithGoogle"];

      if (signin["error"] != null) {
        return setState(() {
          _error = signin["error"];
        });
      }
    } catch (error) {
      logger.w("Google sign in failed: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    var errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(4),
      borderSide: BorderSide(
        color: Colors.yellowAccent,
        width: 2,
      ),
    );
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(2),
            borderSide: BorderSide(
              color: Colors.transparent,
              width: 2,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(
              color: Colors.black.withOpacity(0.7),
              width: 2,
            ),
          ),
          errorBorder: errorBorder,
          focusedErrorBorder: errorBorder,
          errorStyle: TextStyle(
            color: Colors.yellowAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DefaultTextStyle(
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
            ),
            child: LayoutBuilder(
              builder: (context, constraint) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraint.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          SizedBox(height: MediaQuery.of(context).padding.top + 25),
                          Column(
                            children: <Widget>[
                              Text(
                                "OpenVideo",
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "${_hasAccount ? "Log in" : "Sign up"} below to start watching videos.",
                                style: TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 30),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                TextField(
                                  controller: _usernameController,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Username",
                                    errorText: _usernameError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 7),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: !_passwordVisible,
                                  focusNode: _passwordFocus,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    hintText: "Password",
                                    errorText: _passwordError,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    suffixIcon: !_passwordSelected
                                        ? null
                                        : GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _passwordVisible = !_passwordVisible;
                                              });
                                            },
                                            child: Icon(
                                              _passwordVisible ? FontAwesome.eye_slash_solid : FontAwesome.eye_solid,
                                              size: 20,
                                            ),
                                          ),
                                  ),
                                ),
                                if (_error != null)
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    padding: EdgeInsets.only(left: 10, top: 7, bottom: 11),
                                    child: Text(
                                      _error,
                                      style: TextStyle(
                                        color: Colors.yellowAccent,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (_error == null) SizedBox(height: _passwordError != null ? 12 : 8),
                                GradientButton(
                                  onPressed: _hasAccount ? signIn : createAccount,
                                  child: _processing
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: <Widget>[
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                backgroundColor: Colors.transparent,
                                                strokeWidth: 3,
                                              ),
                                            ),
                                            SizedBox(width: 29),
                                            Text(_hasAccount ? "Logging In" : "Creating Account"),
                                          ],
                                        )
                                      : Text(_hasAccount ? "Log in" : "Create Account"),
                                  colors: [Colors.green, Colors.lightGreen],
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Divider(
                                          thickness: 1,
                                          height: 20,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 5),
                                        child: Text(
                                          "OR",
                                          style: TextStyle(
                                            fontFamily: "Roboto",
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15.0,
                                            color: Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                        thickness: 1,
                                        color: Colors.white.withOpacity(0.7),
                                      ))
                                    ],
                                  ),
                                ),
                                GradientButton(
                                  onPressed: googleSignIn,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: <Widget>[
                                      Image.asset(
                                        "assets/images/google-logo.png",
                                        width: 25,
                                        height: 25,
                                      ),
                                      SizedBox(width: 24),
                                      Text("Sign in with Google"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Column(
                            children: <Widget>[
                              Padding(
                                padding: EdgeInsets.all(15),
                                child: RichText(
                                  text: TextSpan(
                                      text: "By ${_hasAccount ? "logging in" : "signing up"}, you agree to our ",
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: "Terms & Conditions",
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: "."),
                                      ]),
                                ),
                              ),
                              Divider(height: 1, color: Colors.white.withOpacity(0.7)),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _error = _usernameError = _passwordError = null;
                                    _hasAccount = !_hasAccount;
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  color: Colors.black.withOpacity(0.1),
                                  padding: EdgeInsets.fromLTRB(15, 15, 15, 15),
                                  child: RichText(
                                    text: TextSpan(
                                      text: _hasAccount ? "Don't have an account? " : "Already have an account? ",
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: _hasAccount ? "Sign up" : "Log in",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(text: "."),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: MediaQuery.of(context).padding.bottom,
                                color: Colors.black.withOpacity(0.1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
}