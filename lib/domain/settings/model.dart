import 'package:flutter/material.dart';

enum ThemeType { LIGHT, DARK, DARKER }

const colors = const {
  'primary': 0xff34C7B5,
};

class Themes {
  static final ThemeData lightTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.light,
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static final ThemeData darkTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.dark,
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
          caption: TextStyle(fontSize: 16, fontWeight: FontWeight.w100),
          button: TextStyle(fontWeight: FontWeight.w100)));

  static final ThemeData darkerTheme = ThemeData(
      primaryColor: const Color(0xff121212),
      brightness: Brightness.dark,
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)),
      textTheme: TextTheme(
          headline: TextStyle(fontWeight: FontWeight.w100),
          title: TextStyle(fontWeight: FontWeight.w100),
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
}

class SettingsStore {
  final ThemeType theme;

  const SettingsStore({this.theme = ThemeType.LIGHT});

  @override
  int get hashCode => theme.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsStore &&
          runtimeType == other.runtimeType &&
          theme == other.theme;

  @override
  String toString() {
    return 'SettingsStore{theme: $theme}';
  }
}
