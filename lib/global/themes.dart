import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';

// Set the theme for the system UI only
void setSystemTheme(ThemeType themeType) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparent means same as app bar
      systemNavigationBarColor: Color(selectSystemUiColor(themeType)),
      systemNavigationBarIconBrightness: selectSystemUiIconColor(themeType),
    ),
  );
}

// Set the theme
// Applies a system theme and returns a ThemeData instance which should be
// applied immediately to match the system UI
ThemeData? setupTheme(ThemeSettings appTheme, {bool generateThemeData = false}) {
  // Set system UI theme
  setSystemTheme(appTheme.themeType);

  // Generate the ThemeData to return if requested
  if (generateThemeData) {
    final primaryColor = Color(appTheme.primaryColor).withOpacity(1);
    final secondaryColor = Color(appTheme.accentColor);
    final brightness = selectThemeBrightness(appTheme.themeType);
    final invertedPrimaryColor = brightness == Brightness.light ? primaryColor : secondaryColor;

    final appBarElevation = selectAppBarElevation(appTheme.themeType);
    final scaffoldBackgroundColor = selectScaffoldBackgroundColor(appTheme.themeType);
    final dialogBackgroundColor = selectModalColor(appTheme.themeType);
    final iconColor = selectIconColor(appTheme.themeType);

    final selectedRowColor = selectRowHighlightColor(appTheme.themeType);

    final fontFamily = selectFontNameString(appTheme.fontName);
    final titleWeight = selectFontTitleWeight(appTheme.fontName);
    final bodyWeight = selectFontBodyWeight(appTheme.fontName);
    final letterSpacing = selectFontLetterSpacing(appTheme.fontName);
    final subtitleSize = selectFontSubtitleSize(appTheme.fontSize);
    final subtitleSizeLarge = selectFontSubtitleSizeLarge(appTheme.fontSize);
    final bodySize = selectFontBodySize(appTheme.fontSize);
    final bodySizeLarge = selectFontBodySizeLarge(appTheme.fontSize);

    return ThemeData(
      // Main Colors
      primaryColor: primaryColor,
      primaryColorBrightness: brightness,
      primaryColorDark: primaryColor,
      primaryColorLight: primaryColor,
      // TODO: remove when secondary / primary color scheme works for Switch() widgets
      // ignore: deprecated_member_use
      accentColor: secondaryColor,
      brightness: brightness,
      colorScheme: ThemeData().colorScheme.copyWith(
            primary: primaryColor,
            secondary: secondaryColor,
            brightness: brightness,
          ),

      // Core UI
      appBarTheme: AppBarTheme(
        elevation: appBarElevation,
        color: Color(appTheme.appBarColor),
        systemOverlayStyle: Color(appTheme.appBarColor).computeLuminance() < 0.5
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      dialogBackgroundColor: dialogBackgroundColor,
      focusColor: primaryColor,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withAlpha(100),
        selectionHandleColor: primaryColor,
      ),
      selectedRowColor: Color(selectedRowColor),
      iconTheme: IconThemeData(color: iconColor),
      scaffoldBackgroundColor:
          scaffoldBackgroundColor != null ? Color(scaffoldBackgroundColor) : null,
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
      fontFamily: fontFamily,
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
          color: secondaryColor,
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
