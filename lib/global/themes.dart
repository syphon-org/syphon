import 'package:dart_json_mapper/dart_json_mapper.dart';
import 'package:flutter/material.dart';
import './colors.dart';

@jsonSerializable
enum ThemeType {
  LIGHT,
  DARK,
  DARKER,
}

class Themes {
  static Color invertedPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : Theme.of(context).accentColor;
  }

  static ThemeData generateCustomTheme({
    int primaryColorHex,
    int accentColorHex,
    ThemeType themeType,
  }) {
    int primaryColor = primaryColorHex ?? TETHERED_CYAN;
    int accentColor = accentColorHex ?? BESIDES_BLUE;
    int appBarColor = primaryColorHex ?? TETHERED_CYAN;
    int scaffoldBackgroundColor = BACKGROUND;

    var brightness = Brightness.light;
    var appBarElevation;

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        primaryColor = primaryColorHex ?? TETHERED_CYAN;
        accentColor = accentColorHex ?? TETHERED_CYAN;
        appBarColor = primaryColorHex ?? BASICALLY_BLACK;
        scaffoldBackgroundColor = null;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        primaryColor = primaryColorHex ?? BASICALLY_BLACK;
        accentColor = accentColorHex ?? TETHERED_CYAN;
        appBarColor = primaryColorHex ?? BASICALLY_BLACK;
        scaffoldBackgroundColor = BASICALLY_BLACK;
        appBarElevation = 0.0;
        break;
      case ThemeType.LIGHT:
      default:
        break;
    }

    final invertedPrimaryColor =
        brightness == Brightness.light ? primaryColor : accentColor;

    return ThemeData(
      // Main Colors
      primaryColor: Color(primaryColor),
      primaryColorDark: Color(primaryColor),
      primaryColorLight: Color(primaryColor),
      accentColor: Color(accentColor),
      brightness: brightness,

      // Core UI
      focusColor: Color(primaryColor),
      cursorColor: Color(primaryColor),
      scaffoldBackgroundColor: scaffoldBackgroundColor != null
          ? Color(scaffoldBackgroundColor)
          : null,
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        brightness: Brightness.dark,
        color: Color(appBarColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        helperStyle: TextStyle(
          color: Color(invertedPrimaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide(
            color: Color(invertedPrimaryColor),
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide(
            color: Color(invertedPrimaryColor),
          ),
        ),
      ),

      // Fonts
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(
        headline6: TextStyle(color: Colors.white),
      ),
      textTheme: TextTheme(
        subtitle1: TextStyle(fontWeight: FontWeight.w100, letterSpacing: 0.4),
        bodyText1: TextStyle(fontWeight: FontWeight.w100, letterSpacing: 0.4),
        headline5: TextStyle(fontWeight: FontWeight.w100),
        headline6: TextStyle(fontWeight: FontWeight.w100, letterSpacing: 0.4),
        subtitle2: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
        caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
        button: TextStyle(fontWeight: FontWeight.w100, letterSpacing: 0.4),
      ),
    );
  }
}
