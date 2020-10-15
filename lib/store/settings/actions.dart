// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/sync/background/service.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetTheme {
  final ThemeType theme;
  SetTheme(this.theme);
}

class SetPrimaryColor {
  final int color;
  SetPrimaryColor({this.color});
}

class SetAvatarShape {
  final String avatarShape;
  SetAvatarShape({this.avatarShape});
}

class SetAccentColor {
  final int color;
  SetAccentColor({this.color});
}

class SetAppBarColor {
  final int color;
  SetAppBarColor({this.color});
}

class SetFontName {
  final String fontName;
  SetFontName({this.fontName});
}

class SetFontSize {
  final String fontSize;
  SetFontSize({this.fontSize});
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

class SetLanguage {
  final String language;
  SetLanguage({this.language});
}

class SetEnterSend {
  final bool enterSend;
  SetEnterSend({this.enterSend});
}

class ToggleRoomTypeBadges {}

class ToggleMembershipEvents {}

class ToggleNotifications {}

class ToggleTypingIndicators {}

class ToggleTimeFormat {}

class ToggleReadReceipts {}

class LogAppAgreement {}

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
      store.dispatch(addAlert(
        error: error,
        message: error,
        origin: 'updateDevice',
      ));
    } finally {
      store.dispatch(fetchDevices());
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Delete a single device
 * ** Fails after recent matix.org update **
 */
ThunkAction<AppState> deleteDevice({String deviceId, bool disableLoading}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final currentCredential =
          store.state.authStore.credential ?? Credential();

      final data = await MatrixApi.deleteDevices(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        deviceIds: [deviceId],
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
      store.dispatch(addAlert(
        error: error,
        message: error,
        origin: 'deleteDevice',
      ));
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
      store.dispatch(addAlert(
        error: error,
        message: error,
        origin: 'deleteDevice(s)',
      ));
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
    store.dispatch(LogAppAgreement());
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
 * Send in a hex value to be used as the secondary color
 */
ThunkAction<AppState> selectAccentColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetAccentColor(color: color));
  };
}

/**
 * Send in a hex value to be used as the app bar color
 */
ThunkAction<AppState> updateAppBarColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetAppBarColor(color: color));
  };
}

/**
 * Iterate over fontFamilies on action
 */
ThunkAction<AppState> incrementFontType() {
  return (Store<AppState> store) async {
    final currentFontType = store.state.settingsStore.fontName;
    final currentIndex = Values.fontFamilies.indexOf(currentFontType);

    store.dispatch(SetFontName(
      fontName:
          Values.fontFamilies[(currentIndex + 1) % Values.fontFamilies.length],
    ));
  };
}

/**
 * Iterate over fontFamilies on action
 */
ThunkAction<AppState> incrementFontSize() {
  return (Store<AppState> store) async {
    final currentFontSize = store.state.settingsStore.fontSize;
    final fontSizes = Values.fontSizes;
    final currentIndex = fontSizes.indexOf(currentFontSize);

    store.dispatch(SetFontSize(
      fontSize: fontSizes[(currentIndex + 1) % fontSizes.length],
    ));
  };
}

/**
 * Iterate over theme types on action
 */
ThunkAction<AppState> incrementTheme() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.theme;
    final themeIndex = ThemeType.values.indexOf(currentTheme);

    store.dispatch(SetTheme(
      ThemeType.values[(themeIndex + 1) % ThemeType.values.length],
    ));
  };
}

ThunkAction<AppState> incrementAvatarShape() {
  return (Store<AppState> store) async {
    final currentShape = store.state.settingsStore.avatarShape;
    var newShape;

    switch (currentShape) {
      case "Circle":
        newShape = 'Square';
        break;
      default:
        newShape = "Circle";
        break;
    }

    store.dispatch(SetAvatarShape(avatarShape: newShape));
  };
}

final languages = ['English', "Russian"];

ThunkAction<AppState> incrementLanguage(context) {
  return (Store<AppState> store) async {
    final languageIndex = languages.indexWhere(
      (name) => name == store.state.settingsStore.language,
    );
    final languageNameNew = languages[(languageIndex + 1) % languages.length];

    store.dispatch(SetLanguage(language: languageNameNew));
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

ThunkAction<AppState> toggleTimeFormat() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleTimeFormat());
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

ThunkAction<AppState> toggleRoomTypeBadges() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleRoomTypeBadges());
  };
}

ThunkAction<AppState> toggleMembershipEvents() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleMembershipEvents());
  };
}

ThunkAction<AppState> toggleNotifications() {
  return (Store<AppState> store) async {
    if (await promptNativeNotificationsRequest(
      pluginInstance: globalNotificationPluginInstance,
    )) {
      store.dispatch(ToggleNotifications());
      final enabled = store.state.settingsStore.notificationsEnabled;
      if (enabled) {
        await BackgroundSync.init();
        BackgroundSync.start(
          protocol: protocol,
          homeserver: store.state.authStore.user.homeserver,
          accessToken: store.state.authStore.user.accessToken,
          lastSince: store.state.syncStore.lastSince,
          currentUser: store.state.authStore.user.userId,
        );

        showBackgroundServiceNotification(
          notificationId: BackgroundSync.service_id,
          pluginInstance: globalNotificationPluginInstance,
        );
      } else {
        BackgroundSync.stop();
        dismissAllNotifications(
          pluginInstance: globalNotificationPluginInstance,
        );
      }
    }
  };
}
