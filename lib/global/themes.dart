import 'package:flutter/material.dart';

enum ThemeType { LIGHT, PRIMARY, DARK, DARKER }

const colors = const {
  'primary': 0xff34C7B5,
};

class Themes {
  static final ThemeData lightTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFFFEFEFE),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      cursorColor: const Color(0xff34C7B5),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
          subtitle: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static final ThemeData primaryTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff34C7B5),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100, color: Colors.white),
          title: TextStyle(fontWeight: FontWeight.w100, color: Colors.white),
          subtitle: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w100, color: Colors.white),
          button: TextStyle(fontWeight: FontWeight.w100, color: Colors.white)));

  static final ThemeData darkTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
          subtitle: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static final ThemeData darkerTheme = ThemeData(
      primaryColor: const Color(0xff121212),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
          subtitle: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static ThemeData getThemeFromKey(ThemeType themeKey) {
    switch (themeKey) {
      case ThemeType.LIGHT:
        return lightTheme;
      // case ThemeType.PRIMARY:
      //   return primaryTheme;
      case ThemeType.DARK:
        return darkTheme;
      case ThemeType.DARKER:
        return darkerTheme;
      default:
        return lightTheme;
    }
  }
}
