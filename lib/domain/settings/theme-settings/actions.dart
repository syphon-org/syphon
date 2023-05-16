import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/theme-settings/model.dart';

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

class SetMainFabLabels {
  final MainFabLabel? fabLabels;
  SetMainFabLabels({this.fabLabels});
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

class ToggleRoomTypeBadges {}

ThunkAction<AppState> toggleRoomTypeBadges() {
  return (Store<AppState> store) async {
    store.dispatch(ToggleRoomTypeBadges());
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

/// Iterate over AvatarShapes on action
ThunkAction<AppState> incrementFabLabels() {
  return (Store<AppState> store) async {
    final currentTheme = store.state.settingsStore.themeSettings;
    final fabTypeIndex = MainFabLabel.values.indexOf(currentTheme.mainFabLabel);

    store.dispatch(SetMainFabLabels(
      fabLabels: MainFabLabel.values[(fabTypeIndex + 1) % MainFabLabel.values.length],
    ));
  };
}
