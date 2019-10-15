import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/domain/index.dart';

import './model.dart';

class SetTheme {
  final ThemeType theme;

  SetTheme(this.theme);
}

ThunkAction<AppState> initSettings() {
  return (Store<AppState> store) async {
    // TODO: get theme selection from local storage
    store.dispatch(SetTheme(ThemeType.LIGHT));
  };
}

ThunkAction<AppState> incrementTheme() {
  return (Store<AppState> store) async {
    ThemeType currentTheme = store.state.settingsStore.theme;
    int themeIndex = ThemeType.values.indexOf(currentTheme);
    print(themeIndex);
    store.dispatch(
        SetTheme(ThemeType.values[(themeIndex + 1) % ThemeType.values.length]));
  };
}
