// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Project imports:
import 'package:syphon/store/settings/theme-settings/model.dart';

import 'colours.dart';

enum ThemeType {
  LIGHT,
  DARK,
  DARKER,
  NIGHT,
}
extension ThemeTypeValues on ThemeType {
  // String representation
  String get name {
    switch (this) {
      case ThemeType.LIGHT: return 'Light';
      case ThemeType.DARK: return 'Dark';
      case ThemeType.DARKER: return 'Darker';
      case ThemeType.NIGHT: return 'Night';
      default: return 'Unknown';
    }
  }
  // Color of the system navbar and other UI
  int get systemUiColor {
    switch (this) {
      case ThemeType.LIGHT: return Colours.whiteDefault;
      case ThemeType.NIGHT: return Colours.blackFull;
      default: return Colours.blackDefault;
    }
  }
  // Brightness of the icons on the system UI
  Brightness get systemUiIconColor {
    switch (this) {
      case ThemeType.LIGHT: return Brightness.dark;
      default: return Brightness.light;
    }
  }
  // The color of the app background
  Color get backgroundBrightness {
    // A non-null assertion is made because the values are hardcoded
    switch (this) {
      case ThemeType.LIGHT: return Colors.grey[200]!;
      case ThemeType.NIGHT: return Colors.grey[500]!;
      default: return Colors.grey[700]!;
    }
  }
  // The brightness of the theme
  Brightness get themeBrightness {
    switch (this) {
      case ThemeType.LIGHT: return Brightness.light;
      default: return Brightness.dark;
    }
  }
  // The color of icons in-app
  Color get iconColor {
    switch (this) {
      case ThemeType.LIGHT: return Colors.grey[500]!;
      default: return Colors.white;
    }
  }
  // The color of modals in-app
  Color? get modalColor {
    switch (this) {
      case ThemeType.NIGHT: return Colors.grey[900]!;
      default: return null;
    }
  }
  // The color of the scaffold
  int? get scaffoldBackgroundColor {
    switch (this) {
      case ThemeType.LIGHT: return Colours.whiteDefault;
      case ThemeType.DARKER: return Colours.blackDefault;
      case ThemeType.NIGHT: return Colours.blackFull;
      default: return null;
    }
  }
  // The elevation of app bar
  double? get appBarElevation {
    switch (this) {
      case ThemeType.DARKER: return 0.0;
      case ThemeType.NIGHT: return 0.0;
      default: return null;
    }
  }
}

enum FontName {
  RUBIK,
  ROBOTO,
  POPPINS,
  INTER,
}
extension FontNameValues on FontName {
  String get name {
    switch (this) {
      case FontName.INTER: return 'Inter';
      case FontName.RUBIK: return 'Rubik';
      case FontName.ROBOTO: return 'Roboto';
      case FontName.POPPINS: return 'Poppins';
      default: return 'Unknown';
    }
  }
  double? get letterSpacing {
    switch (this) {
      case FontName.RUBIK: return 0.5;
      default: return null;
    }
  }
  FontWeight get titleWeight {
    switch (this) {
      case FontName.RUBIK: return FontWeight.w100;
      default: return FontWeight.w400;
    }
  }
  FontWeight get bodyWeight {
    switch (this) {
      default: return FontWeight.w400;
    }
  }
}

enum FontSize {
  SMALL,
  DEFAULT,
  LARGE,
}
extension FontSizeValues on FontSize {
  String get name {
    switch (this) {
      case FontSize.DEFAULT: return 'Default';
      case FontSize.SMALL: return 'Small';
      case FontSize.LARGE: return 'Large';
      default: return 'Unknown';
    }
  }
  double get subtitleSize {
    switch (this) {
      case FontSize.SMALL: return 12;
      case FontSize.LARGE: return 16;
      default: return 14;
    }
  }
  double get subtitleSizeLarge {
    switch (this) {
      case FontSize.SMALL: return 14;
      case FontSize.LARGE: return 18;
      default: return 16;
    }
  }
  double get bodySize {
    switch (this) {
      case FontSize.SMALL: return 16;
      case FontSize.LARGE: return 20;
      default: return 18;
    }
  }
  double get bodySizeLarge {
    switch (this) {
      case FontSize.SMALL: return 18;
      case FontSize.LARGE: return 22;
      default: return 20;
    }
  }
}

enum MessageSize {
  SMALL,
  DEFAULT,
  LARGE,
}
extension MessageSizeValues on MessageSize {
  String get name {
    switch (this) {
      case MessageSize.SMALL: return 'Small';
      case MessageSize.DEFAULT: return 'Default';
      case MessageSize.LARGE: return 'Large';
      default: return 'Unknown';
    }
  }
}

enum AvatarShape {
  CIRCLE,
  SQUARE,
}
extension AvatarShapeValues on AvatarShape {
  String get name {
    switch (this) {
      case AvatarShape.CIRCLE: return 'Circle';
      case AvatarShape.SQUARE: return 'Square';
      default: return 'Unknown';
    }
  }
}

// Set the theme for the system UI
void setSystemTheme(ThemeType themeType, {bool statusTransparent = false}) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: statusTransparent ? Colors.transparent : null,
      systemNavigationBarColor: Color(themeType.systemUiColor),
      systemNavigationBarIconBrightness: themeType.systemUiIconColor,
    ),
  );
}

// Set the theme
// Applies a system theme and returns a ThemeData instance which should be
// applied immediately to match the system UI
ThemeData? setupTheme(AppTheme appTheme, {bool generateThemeData = false}) {
  // Set system UI theme
  setSystemTheme(appTheme.themeType);

  // Generate the ThemeData to return if requested
  if (generateThemeData) {
    final primaryColor = Color(appTheme.primaryColor);
    final accentColor = Color(appTheme.accentColor);
    final scaffoldBackgroundColor = appTheme.themeType.scaffoldBackgroundColor;
    final brightness = appTheme.themeType.themeBrightness;
    final invertedPrimaryColor =
    brightness == Brightness.light ? primaryColor : accentColor;

    final titleWeight = appTheme.fontName.titleWeight;
    final bodyWeight = appTheme.fontName.bodyWeight;
    final letterSpacing = appTheme.fontName.letterSpacing;
    final subtitleSize = appTheme.fontSize.subtitleSize;
    final subtitleSizeLarge = appTheme.fontSize.subtitleSizeLarge;
    final bodySize = appTheme.fontSize.bodySize;
    final bodySizeLarge = appTheme.fontSize.bodySizeLarge;

    return ThemeData(
      // Main Colors
      primaryColor: primaryColor,
      primaryColorDark: primaryColor,
      primaryColorLight: primaryColor,
      accentColor: accentColor,
      brightness: brightness,

      // Core UI
      dialogBackgroundColor: appTheme.themeType.modalColor,
      focusColor: primaryColor,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withAlpha(100),
        selectionHandleColor: primaryColor,
      ),
      iconTheme: IconThemeData(color: appTheme.themeType.iconColor),
      scaffoldBackgroundColor: scaffoldBackgroundColor != null
          ? Color(scaffoldBackgroundColor)
          : null,
      appBarTheme: AppBarTheme(
        elevation: appTheme.themeType.appBarElevation,
        brightness: Brightness.dark,
        color: Color(appTheme.appBarColor),
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
      fontFamily: appTheme.fontName.name,
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
          color: accentColor,
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
