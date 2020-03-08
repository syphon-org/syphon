import 'package:flutter/material.dart';
import './colors.dart';

enum ThemeType { LIGHT, DARK, DARKER }

class Themes {
  static final ThemeData lightTheme = ThemeData(
    primaryColor: PRIMARY_COLOR,
    accentColor: ACCENT_COLOR,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFFFEFEFE),
    fontFamily: 'Rubik',
    primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
    cursorColor: const Color(0xff34C7B5),
    textTheme: TextTheme(
      headline5: TextStyle(fontWeight: FontWeight.w100),
      headline6: TextStyle(fontWeight: FontWeight.w100),
      subtitle2: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
      caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
      button: TextStyle(fontWeight: FontWeight.w100),
    ),
  );

  static final ThemeData primaryTheme = ThemeData(
      primaryColor: const Color(PRIMARY),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xff34C7B5),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline5:
              TextStyle(fontWeight: FontWeight.w100, color: Colors.white),
          headline6:
              TextStyle(fontWeight: FontWeight.w100, color: Colors.white),
          subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w100, color: Colors.white),
          button: TextStyle(fontWeight: FontWeight.w100, color: Colors.white)));

  static final ThemeData darkTheme = ThemeData(
      primaryColor: const Color(PRIMARY),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline5: TextStyle(fontWeight: FontWeight.w100),
          headline6: TextStyle(fontWeight: FontWeight.w100),
          subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static final ThemeData darkerTheme = ThemeData(
      primaryColor: const Color(PRIMARY_DARK),
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline5: TextStyle(fontWeight: FontWeight.w100),
          headline6: TextStyle(fontWeight: FontWeight.w100),
          subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static ThemeData getThemeFromKey(ThemeType themeKey) {
    switch (themeKey) {
      case ThemeType.LIGHT:
        return lightTheme;
      case ThemeType.DARK:
        return darkTheme;
      case ThemeType.DARKER:
        return darkerTheme;
      default:
        return lightTheme;
    }
  }

  static ThemeData getTheme({int primary, int secondary, int}) {
    return ThemeData(
      primaryColor: Color(primary),
      accentColor: Color(secondary),
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFFFEFEFE),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
      cursorColor: const Color(0xff34C7B5),
      textTheme: TextTheme(
        headline5: TextStyle(fontWeight: FontWeight.w100),
        headline6: TextStyle(fontWeight: FontWeight.w100),
        subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
        caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
        button: TextStyle(fontWeight: FontWeight.w100),
      ),
    );
  }
}
