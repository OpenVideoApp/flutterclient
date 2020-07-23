import 'dart:async';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final graphqlClient = new ValueNotifier(
  new GraphQLClient(
    cache: InMemoryCache(),
    link: new AuthInfoLink()
        .concat(HttpLink(uri: "http://openvideo-api.ddns.net:3000/graphql")),
  ),
);

class AuthInfo {
  String username;
  String token;

  static AuthInfo _instance = AuthInfo();

  static AuthInfo instance() {
    return _instance;
  }

  void set(String username, String token) {
    this.username = username;
    this.token = token;
  }
}

class AuthInfoLink extends Link {
  AuthInfoLink()
      : super(request: (Operation operation, [NextLink forward]) {
          StreamController<FetchResult> controller;

          controller = StreamController<FetchResult>(onListen: () async {
            var auth = AuthInfo.instance();
            operation.setContext(<String, Map<String, String>>{
              "headers": <String, String>{
                "username": auth.username,
                "token": auth.token
              },
            });

            await controller.addStream(forward(operation));
            await controller.close();
          });

          return controller.stream;
        });
}
