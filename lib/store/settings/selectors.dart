import 'package:syphon/store/index.dart';

///
/// Font Name
///
String? fontName(AppState state) {
  return state.settingsStore.fontName;
}

///
/// Theming Name
///
String themeTypeName(AppState state) {
  final commonName =
      state.settingsStore.theme.toString().split('.')[1].toLowerCase();
  return commonName.replaceRange(
      0, 1, commonName.substring(0, 1).toUpperCase());
}
