import 'package:flutter/material.dart';
import './colors.dart';

enum ThemeType {
  LIGHT,
  DARK,
  CUSTOM,
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

    switch (themeType) {
      case ThemeType.DARK:
        brightness = Brightness.dark;
        primaryColor = customPrimary ?? BASICALLY_BLACK_COLOR;
        accentColor = customAccent ?? Color(TETHERED_CYAN);
        scaffoldBackgroundColor = null;
        break;
      case ThemeType.DARKER:
        brightness = Brightness.dark;
        primaryColor = customPrimary ?? BASICALLY_BLACK_COLOR;
        accentColor = customAccent ?? Color(TETHERED_CYAN);
        scaffoldBackgroundColor = null;
        break;
      case ThemeType.LIGHT:
      default:
        break;
    }

    final invertedPrimaryColor =
        brightness == Brightness.light ? primaryColor : accentColor;

    return ThemeData(
      // Main Dynamics
      primaryColor: primaryColor,
      primaryColorDark: primaryColor,
      primaryColorLight: primaryColor,
      accentColor: accentColor,
      brightness: brightness,

      // Secondary Dynamics
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      focusColor: primaryColor,
      cursorColor: primaryColor,

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

      // Core UI
      appBarTheme: AppBarTheme(brightness: brightness),

      // Fonts
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(
        headline6: TextStyle(color: Colors.white),
      ),
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
}

// static ThemeData getThemeFromKey(ThemeType themeKey) {
//   switch (themeKey) {
//     case ThemeType.LIGHT:
//       return lightTheme;
//     case ThemeType.DARK:
//       return darkTheme;
//     case ThemeType.DARKER:
//       return darkerTheme;
//     default:
//       return lightTheme;
//   }
// }

//   static final ThemeData lightTheme = ThemeData(
//     primaryColor: PRIMARY_COLOR,
//     accentColor: ACCENT_COLOR,
//     brightness: Brightness.light,
//     appBarTheme: AppBarTheme(
//       brightness: Brightness.dark,
//     ),
//     scaffoldBackgroundColor: BACKGROUND_COLOR,
//     fontFamily: 'Rubik',
//     primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
//     cursorColor: PRIMARY_COLOR,
//     textTheme: TextTheme(
//       headline5: TextStyle(fontWeight: FontWeight.w100),
//       headline6: TextStyle(fontWeight: FontWeight.w100),
//       subtitle2: TextStyle(fontWeight: FontWeight.w400, fontSize: 18),
//       caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
//       button: TextStyle(fontWeight: FontWeight.w100),
//     ),
//   );

//   static final ThemeData darkTheme = ThemeData(
//       primaryColor: const Color(TETHERED_CYAN),
//       brightness: Brightness.dark,
//       appBarTheme: AppBarTheme(
//         brightness: Brightness.dark,
//       ),
//       fontFamily: 'Rubik',
//       primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
//       textTheme: TextTheme(
//           headline5: TextStyle(fontWeight: FontWeight.w100),
//           headline6: TextStyle(fontWeight: FontWeight.w100),
//           subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
//           caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
//           button: TextStyle(fontWeight: FontWeight.w100)));

//   static final ThemeData darkerTheme = ThemeData(
//       primaryColor: const Color(BASICALLY_BLACK),
//       brightness: Brightness.dark,
//       appBarTheme: AppBarTheme(
//         brightness: Brightness.dark,
//       ),
//       fontFamily: 'Rubik',
//       primaryTextTheme: TextTheme(headline6: TextStyle(color: Colors.white)),
//       textTheme: TextTheme(
//           headline5: TextStyle(fontWeight: FontWeight.w100),
//           headline6: TextStyle(fontWeight: FontWeight.w100),
//           subtitle2: TextStyle(fontWeight: FontWeight.w100, fontSize: 18),
//           caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
//           button: TextStyle(fontWeight: FontWeight.w100)));
// }
