import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/models.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';

class SetThemeType {
  final ThemeType themeType;
  SetThemeType(this.themeType);
}

class SetPrimaryColor {
  final int? color;
  SetPrimaryColor({this.color});
}

class SetAvatarShape {
  final AvatarShape? avatarShape;
  SetAvatarShape({this.avatarShape});
}

class SetMainFabType {
  final MainFabType? fabType;
  SetMainFabType({this.fabType});
}

class SetMainFabLocation {
  final MainFabLocation? fabLocation;
  SetMainFabLocation({this.fabLocation});
}

class SetAccentColor {
  final int? color;
  SetAccentColor({this.color});
}

class SetAppBarColor {
  final int? color;
  SetAppBarColor({this.color});
}

class SetFontName {
  final FontName? fontName;
  SetFontName({this.fontName});
}

class SetFontSize {
  final FontSize? fontSize;
  SetFontSize({this.fontSize});
}

class SetMessageSize {
  final MessageSize? messageSize;
  SetMessageSize({this.messageSize});
}

class SetRoomPrimaryColor {
  final int? color;
  final String? roomId;

  SetRoomPrimaryColor({
    this.color,
    this.roomId,
  });
}

class SetPusherToken {
  final String? token;
  SetPusherToken({this.token});
}

class SetLoadingSettings {
  final bool? loading;
  SetLoadingSettings({this.loading});
}

class SetDevices {
  final List<Device>? devices;
  SetDevices({this.devices});
}

class SetLanguage {
  final String? language;
  SetLanguage({this.language});
}

class SetSyncInterval {
  final int syncInterval;
  SetSyncInterval({
    required this.syncInterval,
  });
}

class SetPollTimeout {
  final int pollTimeout;
  SetPollTimeout({
    required this.pollTimeout,
  });
}

class ToggleEnterSend {}

class ToggleAutocorrect {}

class ToggleSuggestions {}

class ToggleAutoDownload {}

class ToggleDismissKeyboard {}

class ToggleRoomTypeBadges {}

class ToggleMembershipEvents {}

class ToggleTypingIndicators {}

class ToggleTimeFormat {}

class SetReadReceipts {
  final ReadReceiptTypes? readReceipts;
  SetReadReceipts({this.readReceipts});
}

class LogAppAgreement {}

/// Fetch Active Devices for account
ThunkAction<AppState> fetchDevices() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = await MatrixApi.fetchDevices(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final List<dynamic> jsonDevices = data['devices'];
      final List<Device> devices =
          jsonDevices.map((jsonDevice) => Device.fromMatrix(jsonDevice)).toList();

      store.dispatch(SetDevices(devices: devices));
    } catch (error) {
      printError('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Fetch Active Devices for account
ThunkAction<AppState> updateDevice({String? deviceId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = await MatrixApi.updateDevice(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: error.toString(),
        origin: 'updateDevice',
      ));
    } finally {
      store.dispatch(fetchDevices());
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Delete device(s)
ThunkAction<AppState> deleteDevices({List<String?>? deviceIds}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final currentCredential = store.state.authStore.credential ?? Credential();

      final data = await MatrixApi.deleteDevices(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        deviceIds: deviceIds,
        session: store.state.authStore.authSession,
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
        message: error.toString(),
        origin: 'deleteDevice(s)',
      ));
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Rename a single device
ThunkAction<AppState> renameDevice({String? deviceId, String? displayName, bool? disableLoading}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final data = await MatrixApi.renameDevice(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        deviceId: deviceId,
        displayName: displayName,
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
        message: error.toString(),
        origin: 'renameDevice',
      ));
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

/// Send in a hex value to be used as the primary color
ThunkAction<AppState> acceptAgreement() {
  return (Store<AppState> store) async {
    store.dispatch(LogAppAgreement());
  };
}

/// Send in a hex value to be used as the primary color
ThunkAction<AppState> setPrimaryColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetPrimaryColor(color: color));
  };
}

/// Send in a hex value to be used as the secondary color
ThunkAction<AppState> setAccentColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetAccentColor(color: color));
  };
}

/// Send in a hex value to be used as the app bar color
ThunkAction<AppState> updateAppBarColor(int color) {
  return (Store<AppState> store) async {
    store.dispatch(SetAppBarColor(color: color));
  };
}

/// Iterate over FontNames on action
ThunkAction<AppState> incrementFontType() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final fontNameIndex = FontName.values.indexOf(currentTheme.fontName);

    store.dispatch(SetFontName(
      fontName: FontName.values[(fontNameIndex + 1) % FontName.values.length],
    ));
  };
}

/// Iterate over FontSizes on action
ThunkAction<AppState> incrementFontSize() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final fontSizeIndex = FontSize.values.indexOf(currentTheme.fontSize);

    store.dispatch(SetFontSize(
      fontSize: FontSize.values[(fontSizeIndex + 1) % FontSize.values.length],
    ));
  };
}

/// Iterate over MessageSizes on action
ThunkAction<AppState> incrementMessageSize() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final messageSizeIndex = MessageSize.values.indexOf(currentTheme.messageSize);

    store.dispatch(SetMessageSize(
      messageSize: MessageSize.values[(messageSizeIndex + 1) % MessageSize.values.length],
    ));
  };
}

/// Iterate over ThemeTypes on action
ThunkAction<AppState> incrementThemeType() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final themeTypeIndex = ThemeType.values.indexOf(currentTheme.themeType);
    final nextThemeType = ThemeType.values[(themeTypeIndex + 1) % ThemeType.values.length];

    // update system navbar theme to match
    setSystemTheme(nextThemeType);

    store.dispatch(SetThemeType(nextThemeType));
  };
}

/// Iterate over AvatarShapes on action
ThunkAction<AppState> incrementAvatarShape() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final avatarShapeIndex = AvatarShape.values.indexOf(currentTheme.avatarShape);

    store.dispatch(SetAvatarShape(
      avatarShape: AvatarShape.values[(avatarShapeIndex + 1) % AvatarShape.values.length],
    ));
  };
}

/// Iterate over AvatarShapes on action
ThunkAction<AppState> incrementFabType() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final fabTypeIndex = MainFabType.values.indexOf(currentTheme.mainFabType);

    store.dispatch(SetMainFabType(
      fabType: MainFabType.values[(fabTypeIndex + 1) % MainFabType.values.length],
    ));
  };
}

/// Iterate over AvatarShapes on action
ThunkAction<AppState> incrementFabLocation() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final fabTypeIndex = MainFabLocation.values.indexOf(currentTheme.mainFabLocation);

    store.dispatch(SetMainFabLocation(
      fabLocation: MainFabLocation.values[(fabTypeIndex + 1) % MainFabLocation.values.length],
    ));
  };
}

ThunkAction<AppState> setLanguage(String? languageCode) {
  return (Store<AppState> store) async {
    store.dispatch(SetLanguage(language: languageCode));
  };
}

ThunkAction<AppState> incrementLanguage() {
  return (Store<AppState> store) async {
    const languages = SupportedLanguages.all;
    final languageIndex = languages.indexWhere(
      (name) => name == store.state.settingsStore.language,
    );
    final languageNameNew = languages[(languageIndex + 1) % languages.length];

    store.dispatch(SetLanguage(language: languageNameNew));
  };
}

Future<bool> homeserverSupportsHiddenReadReceipts(Store<AppState> store) async {
  final version = await MatrixApi.checkVersion(
    protocol: store.state.authStore.protocol,
    homeserver: store.state.authStore.user.homeserver,
  );

  final unstableFeatures = version['unstable_features'];

  return unstableFeatures != null &&
      unstableFeatures.containsKey('org.matrix.msc2285') &&
      unstableFeatures['org.matrix.msc2285'];
}

ThunkAction<AppState> incrementReadReceipts() {
  return (Store<AppState> store) async {
    final readReceiptsIndex =
        ReadReceiptTypes.values.indexOf(store.state.settingsStore.readReceipts);

    final nextReceipt =
        ReadReceiptTypes.values[(readReceiptsIndex + 1) % ReadReceiptTypes.values.length];

    if (nextReceipt != ReadReceiptTypes.Hidden) {
      //short-out
      return store.dispatch(SetReadReceipts(
        readReceipts: nextReceipt,
      ));
    }

    if (await homeserverSupportsHiddenReadReceipts(store)) {
      return store.dispatch(SetReadReceipts(
        readReceipts: ReadReceiptTypes.Hidden,
      ));
    }

    return store.dispatch(SetReadReceipts(
      readReceipts:
          ReadReceiptTypes.values[(readReceiptsIndex + 2) % ReadReceiptTypes.values.length],
    ));
  };
}

ThunkAction<AppState> toggleAutoDownload() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleAutoDownload());
  };
}

ThunkAction<AppState> toggleTypingIndicators() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleTypingIndicators());
  };
}

ThunkAction<AppState> toggleDismissKeyboard() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleDismissKeyboard());
  };
}

ThunkAction<AppState> toggleTimeFormat() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleTimeFormat());
  };
}

ThunkAction<AppState> toggleEnterSend() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleEnterSend());
  };
}

ThunkAction<AppState> toggleAutocorrect() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleAutocorrect());
  };
}

ThunkAction<AppState> toggleSuggestions() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleSuggestions());
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
