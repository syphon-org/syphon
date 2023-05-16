import 'package:syphon/global/https.dart';
import 'package:syphon/domain/settings/chat-settings/actions.dart';
import 'package:syphon/domain/settings/chat-settings/model.dart';
import 'package:syphon/domain/settings/notification-settings/actions.dart';
import 'package:syphon/domain/settings/privacy-settings/actions.dart';
import 'package:syphon/domain/settings/proxy-settings/actions.dart';
import 'package:syphon/domain/settings/storage-settings/actions.dart';
import 'package:syphon/domain/settings/theme-settings/actions.dart';
import './actions.dart';
import './state.dart';

SettingsStore settingsReducer([
  SettingsStore state = const SettingsStore(),
  dynamic actionAny,
]) {
  switch (actionAny.runtimeType) {
    case SetLoadingSettings:
      return state.copyWith(
        loading: actionAny.loading,
      );
    case SetPrimaryColor:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(primaryColor: actionAny.color),
      );
    case SetAccentColor:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(accentColor: actionAny.color),
      );
    case SetAppBarColor:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(appBarColor: actionAny.color),
      );
    case SetFontName:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(fontName: actionAny.fontName),
      );
    case SetFontSize:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(fontSize: actionAny.fontSize),
      );
    case SetMessageSize:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(messageSize: actionAny.messageSize),
      );
    case SetAvatarShape:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(avatarShape: actionAny.avatarShape),
      );
    case SetMainFabType:
      final action = actionAny as SetMainFabType;
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(mainFabType: action.fabType),
      );
    case SetMainFabLocation:
      final action = actionAny as SetMainFabLocation;
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(mainFabLocation: action.fabLocation),
      );
    case SetMainFabLabels:
      final action = actionAny as SetMainFabLabels;
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(mainFabLabel: action.fabLabels),
      );
    case SetDevices:
      return state.copyWith(
        devices: actionAny.devices,
      );
    case SetPusherToken:
      return state.copyWith(
        pusherToken: actionAny.token,
      );
    case LogAppAgreement:
      return state.copyWith(
        alphaAgreement: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    case SetRoomPrimaryColor:
      final chatSettings = Map<String, ChatSetting>.from(state.chatSettings);

      // Initialize chat settings if null
      if (chatSettings[actionAny.roomId] == null) {
        chatSettings[actionAny.roomId] = ChatSetting(
          roomId: actionAny.roomId,
          language: state.language,
        );
      }

      chatSettings[actionAny.roomId] = chatSettings[actionAny.roomId]!.copyWith(
        primaryColor: actionAny.color,
      );
      return state.copyWith(
        chatSettings: chatSettings,
      );
    case SetLanguage:
      return state.copyWith(
        language: actionAny.language,
      );
    case SetThemeType:
      return state.copyWith(
        themeSettings: state.themeSettings.copyWith(themeType: actionAny.themeType),
      );
    case ToggleEnterSend:
      return state.copyWith(
        enterSendEnabled: !state.enterSendEnabled,
      );
    case ToggleAutocorrect:
      return state.copyWith(
        autocorrectEnabled: !state.autocorrectEnabled,
      );
    case ToggleSuggestions:
      return state.copyWith(
        suggestionsEnabled: !state.suggestionsEnabled,
      );
    case SetSyncInterval:
      return state.copyWith(
        syncInterval: actionAny.syncInterval,
      );
    case SetPollTimeout:
      return state.copyWith(
        syncPollTimeout: actionAny.syncPollTimeout,
      );
    case ToggleTypingIndicators:
      return state.copyWith(
        typingIndicatorsEnabled: !state.typingIndicatorsEnabled,
      );
    case ToggleTimeFormat:
      return state.copyWith(
        timeFormat24Enabled: !state.timeFormat24Enabled,
      );
    case ToggleDismissKeyboard:
      return state.copyWith(
        dismissKeyboardEnabled: !state.dismissKeyboardEnabled,
      );
    case ToggleAutoDownload:
      return state.copyWith(
        autoDownloadEnabled: !state.autoDownloadEnabled,
      );
    case SetLastBackupMillis:
      final action = actionAny as SetLastBackupMillis;
      return state.copyWith(
        privacySettings: state.privacySettings.copyWith(
          lastBackupMillis: action.timestamp,
        ),
      );
    case SetKeyBackupPassword:
      // NOTE: saved to cold storage only instead of state
      return state;
    case SetKeyBackupLocation:
      final action = actionAny as SetKeyBackupLocation;
      return state.copyWith(
        storageSettings: state.storageSettings.copyWith(
          keyBackupLocation: action.location,
        ),
      );
    case SetKeyBackupInterval:
      final action = actionAny as SetKeyBackupInterval;
      return state.copyWith(
        privacySettings: state.privacySettings.copyWith(
          keyBackupInterval: action.duration,
          lastBackupMillis: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      );
    case ToggleProxy:
      final state0 = state.copyWith(
        proxySettings: state.proxySettings.copyWith(
          enabled: !state.proxySettings.enabled,
        ),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case SetProxyHost:
      final state0 = state.copyWith(
        proxySettings: state.proxySettings.copyWith(host: actionAny.host),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case SetProxyPort:
      final state0 = state.copyWith(
        proxySettings: state.proxySettings.copyWith(port: actionAny.port),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case ToggleProxyAuthentication:
      final state0 = state.copyWith(
        proxySettings:
            state.proxySettings.copyWith(authenticationEnabled: !state.proxySettings.authenticationEnabled),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case SetProxyUsername:
      final state0 = state.copyWith(
        proxySettings: state.proxySettings.copyWith(username: actionAny.username),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case SetProxyPassword:
      final state0 = state.copyWith(
        proxySettings: state.proxySettings.copyWith(password: actionAny.password),
      );

      httpClient = createClient(proxySettings: state0.proxySettings);

      return state0;
    case SetReadReceipts:
      final action = actionAny as SetReadReceipts;
      return state.copyWith(
        readReceipts: action.readReceipts,
      );
    case ToggleMembershipEvents:
      return state.copyWith(
        membershipEventsEnabled: !state.membershipEventsEnabled,
      );
    case ToggleRoomTypeBadges:
      return state.copyWith(
        roomTypeBadgesEnabled: !state.roomTypeBadgesEnabled,
      );
    case ToggleNotifications:
      return state.copyWith(
        notificationSettings:
            state.notificationSettings.copyWith(enabled: !state.notificationSettings.enabled),
      );
    case SetNotificationSettings:
      return state.copyWith(notificationSettings: actionAny.settings);
    default:
      return state;
  }
}
