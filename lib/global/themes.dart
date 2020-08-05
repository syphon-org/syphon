// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:hive/hive.dart';

// Project imports:
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'colours.dart';

part 'themes.g.dart';

@HiveType(typeId: ThemeTypeHiveId)
enum ThemeType {
  @HiveField(0)
  LIGHT,
  @HiveField(1)
  DARK,
  @HiveField(2)
  DARKER,
  @HiveField(3)
  NIGHT,
}

const List<String> fontTypes = [
  'Rubik',
  "Roboto",
];

class Themes {
  static Color invertedPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : Theme.of(context).accentColor;
  }

  static ThemeData generateCustomTheme({
    int primaryColorHex,
    int accentColorHex,
    int appBarColorHex,
    String fontName,
    ThemeType themeType,
  }) {
    int primaryColor = primaryColorHex ?? Colours.cyanSyphon;
    int accentColor = accentColorHex ?? Colours.cyanSyphon;
    int appBarColor = appBarColorHex;
    int scaffoldBackgroundColor = Colours.whiteDefault;

    var appBarElevation;
    var modalColor;
    var brightness = Brightness.light;
    var iconColor = Colors.grey[500];

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        iconColor = Colors.white;
        primaryColor = primaryColorHex ?? Colours.cyanSyphon;
        accentColor = accentColorHex ?? Colours.cyanSyphon;
        appBarColor = appBarColor ?? Colours.blackDefault;
        scaffoldBackgroundColor = null;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        appBarElevation = 0.0;
        iconColor = Colors.white;
        primaryColor = primaryColorHex ?? Colours.cyanSyphon;
        accentColor = accentColorHex ?? Colours.cyanSyphon;
        appBarColor = appBarColor ?? Colours.blackDefault;
        scaffoldBackgroundColor = Colours.blackDefault;
        break;
      case ThemeType.NIGHT:
        brightness = Brightness.dark;
        appBarElevation = 0.0;
        iconColor = Colors.white;
        modalColor = Colors.grey[900];
        primaryColor = primaryColorHex ?? Colours.cyanSyphon;
        accentColor = accentColorHex ?? Colours.cyanSyphon;
        appBarColor = appBarColor ?? Colours.blackFull;
        scaffoldBackgroundColor = Colours.blackFull;
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

      // Core UI\
      dialogBackgroundColor: modalColor,
      focusColor: Color(primaryColor),
      cursorColor: Color(primaryColor),
      iconTheme: IconThemeData(color: iconColor),
      textSelectionColor: Color(primaryColor).withAlpha(100),
      textSelectionHandleColor: Color(primaryColor),
      scaffoldBackgroundColor: scaffoldBackgroundColor != null
          ? Color(scaffoldBackgroundColor)
          : null,
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        brightness: Brightness.dark,
        color: Color(appBarColor ?? primaryColorHex),
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
      fontFamily: fontName ?? 'Rubik',
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
