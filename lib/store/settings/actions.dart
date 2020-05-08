import 'dart:convert';

import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:http/http.dart' as http;
import 'package:Tether/global/libs/matrix/devices.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/global/themes.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetTheme {
  final ThemeType theme;
  SetTheme(this.theme);
}

class SetPrimaryColor {
  final int color;
  SetPrimaryColor({this.color});
}

class SetRoomPrimaryColor {
  final int color;
  final String roomId;

  SetRoomPrimaryColor({
    this.color,
    this.roomId,
  });
}

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetDevices {
  final List<DeviceSetting> devices;
  SetDevices({this.devices});
}

class SetAccentColor {
  final int color;
  SetAccentColor({this.color});
}

class SetLanguage {
  final String language;
  SetLanguage({this.language});
}

class SetEnterSend {
  final bool enterSend;
  SetEnterSend({this.enterSend});
}

class ToggleMembershipEvents {
  final bool membershipEventsEnabled;
  ToggleMembershipEvents({this.membershipEventsEnabled});
}

class ToggleNotifications {
  ToggleNotifications();
}

class ToggleTypingIndicators {
  ToggleTypingIndicators();
}

class ToggleReadReceipts {
  ToggleReadReceipts();
}

/**
 * Fetch Remote Push Notification Settings
 */
ThunkAction<AppState> fetchPushNotificationSettings(int color) {
  return (Store<AppState> store) async {};
}

/**
 * Fetch Active Devices for account
 */
ThunkAction<AppState> fetchDevices() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      final request = buildDevicesRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);
      print('[fetchDevices] $data');
      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> jsonDevices = data['devices'];
      final List<DeviceSetting> devices = jsonDevices
          .map((jsonDevice) => DeviceSetting.fromJson(jsonDevice))
          .toList();

      store.dispatch(SetDevices(devices: devices));
    } catch (error) {
      print('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
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

ThunkAction<AppState> toggleReadReceipts() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleReadReceipts());
  };
}

ThunkAction<AppState> toggleTypingIndicators() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleTypingIndicators());
  };
}

ThunkAction<AppState> toggleEnterSend() {
  return (Store<AppState> store) async {
    store.dispatch(
      SetEnterSend(
        enterSend: !store.state.settingsStore.enterSend,
      ),
    );
  };
}

ThunkAction<AppState> toggleMembershipEvents() {
  return (Store<AppState> store) async {
    store.dispatch(
      ToggleMembershipEvents(
        membershipEventsEnabled:
            !store.state.settingsStore.membershipEventsEnabled,
      ),
    );
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
