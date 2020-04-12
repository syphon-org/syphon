import 'package:Tether/global/notifications.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/global/themes.dart';

class SetTheme {
  final ThemeType theme;
  SetTheme(this.theme);
}

class SetPrimaryColor {
  final int color;
  SetPrimaryColor({this.color});
}

class SetAccentColor {
  final int color;
  SetAccentColor({this.color});
}

class SetLanguage {
  final String language;
  SetLanguage({this.language});
}

class ToggleNotifications {
  ToggleNotifications();
}

ThunkAction<AppState> initSettings() {
  return (Store<AppState> store) async {
    // TODO: get theme selection from local storage
    store.dispatch(SetTheme(ThemeType.LIGHT));
  };
}

/**
 * Send in a hex value to be used as the primary color
 */
ThunkAction<AppState> selectPrimaryColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetPrimaryColor(color: color));
  };
}

/**
 * Send in a hex value to be used as the primary color
 */
ThunkAction<AppState> selectAccentColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetAccentColor(color: color));
  };
}

/**
 * Send in a hex value to be used as the primary color
 */
ThunkAction<AppState> updateLanguage(String language) {
  return (Store<AppState> store) async {
    store.dispatch(SetLanguage(language: language));
  };
}

ThunkAction<AppState> toggleNotifications() {
  return (Store<AppState> store) async {
    if (await promptNativeNotificationsRequest(
      pluginInstance: globalNotificationPluginInstance,
    )) {
      store.dispatch(ToggleNotifications());
    }
  };
}

ThunkAction<AppState> incrementTheme() {
  return (Store<AppState> store) async {
    ThemeType currentTheme = store.state.settingsStore.theme;
    int themeIndex = ThemeType.values.indexOf(currentTheme);
    store.dispatch(
        SetTheme(ThemeType.values[(themeIndex + 1) % ThemeType.values.length]));
  };
}
