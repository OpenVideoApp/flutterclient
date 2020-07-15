import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterclient/fontawesome/font_awesome_icons.dart';
import 'package:flutterclient/tabs/create.dart';
import 'package:flutterclient/tabs/home.dart';
import 'package:flutterclient/tabs/profile.dart';
import 'package:flutterclient/ui/themes.dart';
import 'package:flutterclient/ui/uihelpers.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

final _lightTheme = BaseTheme(
  isDark: false,
  bg1: Colors.white,
  accent1: Colors.grey[600]
).themeData;

final _darkTheme = BaseTheme(
  isDark: true,
  bg1: Colors.black,
  accent1: Colors.grey
).themeData;

final graphqlClient = ValueNotifier(
  GraphQLClient(
    cache: InMemoryCache(),
    link: HttpLink(
      uri: "https://7jqrk8zydc.execute-api.ap-southeast-2.amazonaws.com/Prod/graphql"
    )
  )
);


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
        theme: _lightTheme,
        home: MainScreen()
      )
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({Key key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedTab;
  StreamController _changeNotifier = new StreamController.broadcast();

  @override
  void initState() {
    super.initState();
    _selectedTab = 0;
  }

  Widget _navBar() {
    ThemeData theme = _selectedTab == 0 ? _darkTheme : _lightTheme;
    return Container(
      decoration: _selectedTab == 0 ? null : BoxDecoration(
        border: Border(
          top: BorderSide(
            width: 1,
            color: theme.accentColor
          )
        )
      ),
      child: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text("Home")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            title: Text("Search")
          ),
          BottomNavigationBarItem(
            icon: Icon(FontAwesome.video_plus_solid),
            title: Text("Create")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            title: Text("Chat")
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text("Profile")
          )
        ],
        backgroundColor: theme.backgroundColor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedTab,
        showUnselectedLabels: true,
        selectedItemColor: theme.textTheme.bodyText1.color,
        unselectedItemColor: theme.accentColor,
        onTap: (index) {
          setState(() {
            _changeNotifier.sink.add(
              NavInfo(
                type: NavInfoType.Tab,
                from: _selectedTab,
                to: index
              )
            );
            _selectedTab = index;
          });
        },
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = _selectedTab == 0 ? _darkTheme : Theme.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: IndexedStack(
          children: <Widget>[
            HomeTab(
              shouldTriggerChange: _changeNotifier.stream
            ),
            Container(),
            _selectedTab == 2 ? CreateTab() : Container(),
            Container(
              color: Colors.red,
              alignment: Alignment.center,
              child: Text("Chat")
            ),
            ProfileTab()
          ],
          index: _selectedTab
        )
      ),
      bottomNavigationBar: _navBar()
    );
  }

  @override
  void dispose() {
    _changeNotifier.close();
    super.dispose();
  }
}