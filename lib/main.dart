import 'package:flutter/material.dart';
import 'package:flutterclient/ui/screens/login.dart';
import 'package:flutterclient/ui/screens/main.dart';
import 'package:flutterclient/ui/themes.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final graphqlClient = ValueNotifier(
  GraphQLClient(
    cache: InMemoryCache(),
    link: HttpLink(
      //uri: "https://7jqrk8zydc.execute-api.ap-southeast-2.amazonaws.com/Prod/graphql"
      uri: "http://10.0.2.2:3000/graphql"
    )
  )
);

bool loggedIn = false;

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
        home: loggedIn ? MainScreen() : LoginScreen()
      )
    );
  }
}
