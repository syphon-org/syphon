import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import './colors.dart';

part 'themes.g.dart';

@HiveType(typeId: ThemeTypeHiveId)
enum ThemeType {
  @HiveField(0)
  LIGHT,
  @HiveField(1)
  DARK,
  @HiveField(2)
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
    int primaryColor = primaryColorHex ?? Colours.cyanSyphon;
    int accentColor = accentColorHex ?? Colours.cyanSyphon;
    int appBarColor = primaryColorHex ?? Colours.cyanSyphon;
    int scaffoldBackgroundColor = Colours.whiteDefault;

    var brightness = Brightness.light;
    var appBarElevation;

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        primaryColor = primaryColorHex ?? Colours.cyanSyphon;
        accentColor = accentColorHex ?? Colours.cyanSyphon;
        appBarColor = primaryColorHex ?? Colours.blackDefault;
        scaffoldBackgroundColor = null;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        primaryColor = primaryColorHex ?? Colours.cyanSyphon;
        accentColor = accentColorHex ?? Colours.cyanSyphon;
        appBarColor = primaryColorHex ?? Colours.blackDefault;
        scaffoldBackgroundColor = Colours.blackDefault;
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
      textSelectionColor: Color(primaryColor).withAlpha(100),
      textSelectionHandleColor: Color(primaryColor),
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
        headline6: TextStyle(
          color: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        headline5: TextStyle(
          fontWeight: FontWeight.w100,
        ),
        headline6: TextStyle(
          fontWeight: FontWeight.w100,
          letterSpacing: 0.4,
        ),
        subtitle1: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w100,
          letterSpacing: 0.4,
        ),
        subtitle2: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(accentColor),
        ),
        overline: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w100,
          letterSpacing: 0.4,
        ),
        bodyText1: TextStyle(
          fontSize: 20,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w400,
        ),
        bodyText2: TextStyle(
          fontSize: 18,
          letterSpacing: 0.4,
          fontWeight: FontWeight.w100,
        ),
        caption: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w100,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
