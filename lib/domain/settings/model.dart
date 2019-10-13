import 'package:flutter/material.dart';

enum ThemeType { LIGHT, DARK, DARKER }

class Themes {
  static final ThemeData lightTheme = ThemeData(
      primaryColor: const Color(0xff34C7B5),
      brightness: Brightness.light,
      fontFamily: 'Rubik',
      primaryTextTheme: TextTheme(title: TextStyle(color: Colors.white)));

  static final ThemeData darkTheme = ThemeData(
    primaryColor: Colors.grey,
    brightness: Brightness.dark,
  );

  static final ThemeData darkerTheme = ThemeData(
    primaryColor: Colors.black,
    brightness: Brightness.dark,
  );

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
    return 'SettingsStore{user: $theme}';
  }
}
