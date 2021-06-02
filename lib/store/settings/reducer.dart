// Project imports:
import 'package:syphon/store/settings/chat-settings/model.dart';
import './actions.dart';
import './state.dart';

SettingsStore settingsReducer(
    [SettingsStore state = const SettingsStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(
        loading: action.loading,
      );
    case SetPrimaryColor:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(primaryColor: action.color),
      );
    case SetAccentColor:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(accentColor: action.color),
      );
    case SetAppBarColor:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(appBarColor: action.color),
      );
    case SetFontName:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(fontName: action.fontName),
      );
    case SetFontSize:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(fontSize: action.fontSize),
      );
    case SetMessageSize:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(messageSize: action.messageSize),
      );
    case SetAvatarShape:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(avatarShape: action.avatarShape),
      );
    case SetDevices:
      return state.copyWith(
        devices: action.devices,
      );
    case SetPusherToken:
      return state.copyWith(
        pusherToken: action.token,
      );
    case LogAppAgreement:
      return state.copyWith(
        alphaAgreement: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    case SetRoomPrimaryColor:
      final chatSettings =
          Map<String, ChatSetting>.from(state.customChatSettings ?? Map());

      // Initialize chat settings if null
      if (chatSettings[action.roomId] == null) {
        chatSettings[action.roomId] = ChatSetting();
      }

      chatSettings[action.roomId] = chatSettings[action.roomId]!.copyWith(
        primaryColor: action.color,
      );
      return state.copyWith(
        customChatSettings: chatSettings,
      );
    case SetLanguage:
      return state.copyWith(
        language: action.language,
      );
    case SetThemeType:
      return state.copyWith(
        appTheme: state.appTheme.copyWith(themeType: action.themeType),
      );
    case ToggleEnterSend:
      return state.copyWith(
        enterSend: !state.enterSend,
      );
    case ToggleTypingIndicators:
      return state.copyWith(
        typingIndicators: !state.typingIndicators,
      );
    case ToggleTimeFormat:
      return state.copyWith(
        timeFormat24Enabled: !state.timeFormat24Enabled,
      );
    case ToggleDismissKeyboard:
      return state.copyWith(
        dismissKeyboardEnabled: !state.dismissKeyboardEnabled,
      );
    case ToggleReadReceipts:
      return state.copyWith(
        readReceipts: !state.readReceipts,
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
        notificationsEnabled: !state.notificationsEnabled,
      );
    default:
      return state;
  }
}
