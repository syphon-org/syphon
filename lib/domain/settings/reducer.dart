import './model.dart';
import './actions.dart';

SettingsStore settingsReducer(
    [SettingsStore state = const SettingsStore(), dynamic action]) {
  switch (action.runtimeType) {
    case ToggleNotifications:
      return state.copyWith(
        notificationsEnabled: !state.notificationsEnabled,
      );
    case SetTheme:
      return new SettingsStore(
        theme: action.theme,
      );
    default:
      return state;
  }
}
