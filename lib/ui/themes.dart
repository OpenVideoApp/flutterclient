import 'package:flutter/material.dart';

class BaseTheme {
  Color bg1;
  Color accent1;
  bool isDark;

  BaseTheme({@required this.isDark, this.bg1, this.accent1});

  ThemeData get themeData {
    TextTheme txtTheme = (isDark ? ThemeData.dark() : ThemeData.light())
      .textTheme;
    Color txtColor = txtTheme.bodyText1.color;
    ColorScheme colorScheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accent1,
      primaryVariant: accent1,
      secondary: accent1,
      secondaryVariant: accent1,
      background: bg1,
      surface: bg1,
      onBackground: txtColor,
      onSurface: txtColor,
      onError: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      error: Colors.red.shade400
    );

    var t = ThemeData.from(
      textTheme: txtTheme,
      colorScheme: colorScheme
    ).copyWith(
      buttonColor: accent1,
      cursorColor: accent1,
      highlightColor: accent1,
      toggleableActiveColor: accent1
    );

    return t;
  }
}