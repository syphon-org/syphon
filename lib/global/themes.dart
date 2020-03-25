import 'package:flutter/material.dart';
import './colors.dart';

enum ThemeType {
  LIGHT,
  DARK,
  CUSTOM,
  DARKER,
}

class Themes {
  static ThemeData generateCustomTheme({
    Color primary,
    Color accent,
    ThemeType themeType,
  }) {
    var brightness = Brightness.light;
    var scaffoldBackgroundColor = BACKGROUND_COLOR;
    var primaryColor = primary ?? PRIMARY_COLOR;
    var aceentColor = accent ?? ACCENT_COLOR;

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        primaryColor = PRIMRARY_DARK_COLOR;
        scaffoldBackgroundColor = PRIMARY_COLOR;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        primaryColor = PRIMRARY_DARK_COLOR;
        break;
      case ThemeType.LIGHT:
      default:
        brightness = Brightness.light;
        scaffoldBackgroundColor = BACKGROUND_COLOR;
        break;
    }

    return ThemeData(
      primaryColor: primaryColor,
      accentColor: aceentColor,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cursorColor: PRIMARY_COLOR,

      // Always the same
      appBarTheme: AppBarTheme(brightness: Brightness.dark),
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
        headline5: TextStyle(fontWeight: FontWeight.w100),
        headline6: TextStyle(fontWeight: FontWeight.w100),
        subtitle2: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
        button: TextStyle(
          fontWeight: FontWeight.w100,
        ),
      ),
    );
  }

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

  static final ThemeData lightTheme = ThemeData(
    primaryColor: PRIMARY_COLOR,
    accentColor: ACCENT_COLOR,
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: BACKGROUND_COLOR,
    fontFamily: 'Rubik',
    primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
    cursorColor: PRIMARY_COLOR,
    textTheme: TextTheme(
      headline5: TextStyle(fontWeight: FontWeight.w100),
      headline6: TextStyle(fontWeight: FontWeight.w100),
      subtitle2: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
      caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
      button: TextStyle(fontWeight: FontWeight.w100),
    ),
  );

  static final ThemeData primaryTheme = ThemeData(
      primaryColor: PRIMARY_COLOR,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: PRIMARY_COLOR,
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
}
