import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colours.dart';

enum ThemeType {
  LIGHT,
  DARK,
  DARKER,
  NIGHT,
}

///
/// Init System Theme
///
/// Written by TR_SLimey
///
void initSystemTheme(ThemeType themeType, {bool statusTransparent = false}) {
  var themeNavbarColour;
  var themeNavbarIconBrightness;

  switch (themeType) {
    case ThemeType.LIGHT:
      // TODO: transparent setting
      // themeNavbarColour = Colors.transparent.value;
      // themeNavbarIconBrightness = Brightness.light;

      themeNavbarColour = Colours.whiteDefault;
      themeNavbarIconBrightness = Brightness.dark;
      break;
    case ThemeType.NIGHT:
      themeNavbarColour = Colours.blackFull;
      themeNavbarIconBrightness = Brightness.light;
      break;
    default:
      themeNavbarColour = Colours.blackDefault;
      themeNavbarIconBrightness = Brightness.light;
  }

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: statusTransparent ? Colors.transparent : null,
      systemNavigationBarColor: Color(themeNavbarColour),
      systemNavigationBarIconBrightness: themeNavbarIconBrightness,
    ),
  );
}

class Themes {
  static Color? backgroundBrightness(ThemeType type) {
    switch (type) {
      case ThemeType.LIGHT:
        return Color(Colours.greyLightest);
      case ThemeType.NIGHT:
        return Color(Colours.greyDefault);
      default:
        return Color(Colours.greyDark);
    }
  }

  static Color invertedPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).primaryColor
        : Theme.of(context).accentColor;
  }

  static ThemeData generateCustomTheme({
    int? primaryColorHex,
    int? accentColorHex,
    int? appBarColorHex,
    String? fontName,
    String? fontSize,
    ThemeType? themeType,
  }) {
    int primaryColor = primaryColorHex ?? Colours.cyanSyphon;
    int accentColor = accentColorHex ?? Colours.cyanSyphon;
    int? appBarColor = appBarColorHex;
    int? scaffoldBackgroundColor = Colours.whiteDefault;

    var modalColor;
    var appBarElevation;
    var brightness = Brightness.light;
    var iconColor = Color(Colours.greyDefault);

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

    var titleWeight = FontWeight.w400;
    var bodyWeight = FontWeight.w400;

    double? letterSpacing;
    switch (fontName) {
      case 'Rubik':
        titleWeight = FontWeight.w100;
        bodyWeight = FontWeight.w400;
        letterSpacing = 0.5;
        break;
      default:
        break;
    }
    double subtitleSize;
    double subtitleSizeLarge;
    double bodySize;
    double bodySizeLarge;
    switch (fontSize) {
      case 'Small':
        subtitleSize = 12;
        subtitleSizeLarge = 14;
        bodySize = 16;
        bodySizeLarge = 18;
        break;
      case 'Large':
        subtitleSize = 16;
        subtitleSizeLarge = 18;
        bodySize = 20;
        bodySizeLarge = 22;
        break;
      default:
        subtitleSize = 14;
        subtitleSizeLarge = 16;
        bodySize = 18;
        bodySizeLarge = 20;
        break;
    }

    final invertedPrimaryColor = brightness == Brightness.light ? primaryColor : accentColor;

    return ThemeData(
      // Main Colors
      primaryColor: Color(primaryColor),
      primaryColorDark: Color(primaryColor),
      primaryColorLight: Color(primaryColor),
      accentColor: Color(accentColor),
      accentIconTheme: IconThemeData(color: Color(accentColor)),
      colorScheme: ThemeData().colorScheme.copyWith(
            primary: Color(primaryColor),
            secondary: Color(accentColor),
          ),
      brightness: brightness,

      // Core UI\
      dialogBackgroundColor: modalColor,
      focusColor: Color(primaryColor),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Color(primaryColor),
        selectionColor: Color(primaryColor).withAlpha(100),
        selectionHandleColor: Color(primaryColor),
      ),
      iconTheme: IconThemeData(color: iconColor),
      scaffoldBackgroundColor: scaffoldBackgroundColor != null ? Color(scaffoldBackgroundColor) : null,
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        brightness: Brightness.dark,
        color: Color(appBarColor ?? primaryColorHex!),
      ),
      inputDecorationTheme: InputDecorationTheme(
        helperStyle: TextStyle(
          color: Color(invertedPrimaryColor),
        ),
        focusColor: Color(invertedPrimaryColor),
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
          fontWeight: titleWeight,
        ),
      ),
      textTheme: TextTheme(
        headline5: TextStyle(
          fontWeight: titleWeight,
        ),
        headline6: TextStyle(
          fontWeight: titleWeight,
          letterSpacing: letterSpacing,
        ),
        subtitle1: TextStyle(
          fontSize: subtitleSizeLarge,
          fontWeight: titleWeight,
          letterSpacing: letterSpacing,
        ),
        subtitle2: TextStyle(
          fontSize: subtitleSize,
          fontWeight: bodyWeight,
          letterSpacing: letterSpacing,
          color: Color(accentColor),
        ),
        caption: TextStyle(
          fontSize: subtitleSize,
          fontWeight: titleWeight,
          letterSpacing: letterSpacing,
        ),
        bodyText1: TextStyle(
          fontSize: bodySizeLarge,
          letterSpacing: letterSpacing,
          fontWeight: bodyWeight,
        ),
        bodyText2: TextStyle(
          fontSize: bodySize,
          letterSpacing: letterSpacing,
          fontWeight: titleWeight,
        ),
      ),
    );
  }
}
