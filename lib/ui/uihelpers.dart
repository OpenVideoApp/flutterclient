import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum NavInfoType {
  Tab, Video
}

class NavInfo {
  NavInfoType type;
  int from, to;

  NavInfo({@required this.type, @required this.from, @required this.to});
}

// Applies bold formatting to tags
Widget formatText(String text) {
  List<String> words = text.split(" ");
  List<TextSpan> formattedWords = [];

  for (int i = 0; i < words.length; i++) {
    String word = words[i];
    if (word.indexOf("#") == 0 || word.indexOf("@") == 0) {
      formattedWords.add(
        TextSpan(
          text: word,
          style: TextStyle(fontWeight: FontWeight.bold)
        )
      );
    } else {
      formattedWords.add(
        TextSpan(text: word)
      );
    }
    if (i < words.length) formattedWords.add(TextSpan(text: " "));
  }

  return RichText(
    text: TextSpan(
      text: "",
      style: TextStyle(
        color: Colors.white,
        fontSize: 15
      ),
      children: formattedWords
    )
  );
}

String compactNumber(int number) {
  return NumberFormat.compactCurrency(
    decimalDigits: 0,
    symbol: ""
  ).format(number);
}