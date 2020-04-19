import './model.dart';
import './actions.dart';

SettingsStore settingsReducer(
    [SettingsStore state = const SettingsStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetPrimaryColor:
      return state.copyWith(
        primaryColor: action.color,
      );
    case SetAccentColor:
      return state.copyWith(
        accentColor: action.color,
      );
    case SetLanguage:
      return state.copyWith(
        language: action.language,
      );
    case SetTheme:
      return state.copyWith(
        theme: action.theme,
      );
    case SetEnterSend:
      return state.copyWith(
        enterSend: action.enterSend,
      );
    case ToggleNotifications:
      return state.copyWith(
        notificationsEnabled: !state.notificationsEnabled,
      );
    default:
      return state;
  }
}
