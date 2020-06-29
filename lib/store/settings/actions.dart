import 'package:flutter/material.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/global/notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/global/themes.dart';

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

class SetPusherToken {
  final String token;
  SetPusherToken({this.token});
}

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetDevices {
  final List<Device> devices;
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

class SetAppAgreement {
  SetAppAgreement();
}

/**
 * Fetch Active Devices for account
 */
ThunkAction<AppState> fetchDevices() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchDevices(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> jsonDevices = data['devices'];
      final List<Device> devices =
          jsonDevices.map((jsonDevice) => Device.fromJson(jsonDevice)).toList();

      store.dispatch(SetDevices(devices: devices));
    } catch (error) {
      debugPrint('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Fetch Active Devices for account
 */
ThunkAction<AppState> updateDevice({String deviceId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.updateDevice(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      debugPrint('[updateDevice] $error');
      store.dispatch(addAlert(type: 'warning', message: error));
    } finally {
      store.dispatch(fetchDevices());
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Delete a device
 */
ThunkAction<AppState> deleteDevice({String deviceId, bool disableLoading}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final currentCredential =
          store.state.authStore.credential ?? Credential();

      final data = await MatrixApi.deleteDevice(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        deviceId: deviceId,
        session: store.state.authStore.session,
        userId: store.state.authStore.user.userId,
        authType: MatrixAuthTypes.PASSWORD,
        authValue: currentCredential.value,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // If a flow exists, more authentication is needed before
      // attempting to delete again
      if (data['flows'] != null) {
        return store.dispatch(setInteractiveAuths(auths: data));
      }

      store.dispatch(fetchDevices());
      return true;
    } catch (error) {
      debugPrint('[deleteDevice] $error');
      store.dispatch(addAlert(type: 'warning', message: error));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Delete multiple devices
 */
ThunkAction<AppState> deleteDevices({List<String> deviceIds}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final currentCredential =
          store.state.authStore.credential ?? Credential();

      final data = await MatrixApi.deleteDevices(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        deviceIds: deviceIds,
        session: store.state.authStore.session,
        userId: store.state.authStore.user.userId,
        authType: MatrixAuthTypes.PASSWORD,
        authValue: currentCredential.value,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      if (data['flows'] != null) {
        return store.dispatch(setInteractiveAuths(auths: data));
      }

      store.dispatch(fetchDevices());
      return true;
    } catch (error) {
      debugPrint('[deleteDevice(s)] $error');
      store.dispatch(addAlert(type: 'warning', message: error));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Send in a hex value to be used as the primary color
 */
ThunkAction<AppState> acceptAgreement() {
  return (Store<AppState> store) async {
    store.dispatch(SetAppAgreement());
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
