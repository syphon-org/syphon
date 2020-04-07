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

class ToggleNotifications {
  ToggleNotifications();
}

ThunkAction<AppState> initSettings() {
  return (Store<AppState> store) async {
    // TODO: get theme selection from local storage
    store.dispatch(SetTheme(ThemeType.LIGHT));
  };
}

ThunkAction<AppState> updatePrimaryColor() {
  return (Store<AppState> store) async {
    int primaryColor = store.state.settingsStore.primaryColor;

    Color(primaryColor);
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
