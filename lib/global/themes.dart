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
    Color customPrimary,
    Color customAccent,
    ThemeType themeType,
  }) {
    // final accentFontColor = Colors.grey[500];

    var brightness = Brightness.light;
    var primaryColor = customPrimary ?? PRIMARY_COLOR;
    var accentColor = customAccent ?? ACCENT_COLOR;
    var scaffoldBackgroundColor = BACKGROUND_COLOR;
    var appBarColor = PRIMARY_COLOR;
    var appBarElevation;

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        primaryColor = customPrimary ?? PRIMARY_COLOR;
        accentColor = customAccent ?? Color(TETHERED_CYAN);
        scaffoldBackgroundColor = null;
        appBarColor = customPrimary ?? BASICALLY_BLACK_COLOR;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        primaryColor = customPrimary ?? BASICALLY_BLACK_COLOR;
        accentColor = customAccent ?? Color(TETHERED_CYAN);
        scaffoldBackgroundColor = BASICALLY_BLACK_COLOR;
        appBarColor = customPrimary ?? BASICALLY_BLACK_COLOR;
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
      primaryColor: primaryColor,
      primaryColorDark: primaryColor,
      primaryColorLight: primaryColor,
      accentColor: accentColor,
      brightness: brightness,

      // Core UI
      focusColor: primaryColor,
      cursorColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        brightness: Brightness.dark,
        color: appBarColor,
      ),
      inputDecorationTheme: InputDecorationTheme(
        helperStyle: TextStyle(
          color: invertedPrimaryColor,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide(
            color: invertedPrimaryColor,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide(
            color: invertedPrimaryColor,
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
