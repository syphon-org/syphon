import './model.dart';
import './actions.dart';

SettingsStore settingsReducer(
    [SettingsStore state = const SettingsStore(), dynamic action]) {
  print('Settings Reducer $action');
  switch (action.runtimeType) {
    case SetTheme:
      return new SettingsStore(
        theme: action.theme,
      );
    default:
      return state;
  }
}
