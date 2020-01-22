import 'package:Tether/global/colors.dart';
import "package:Tether/global/themes.dart";

class SettingsStore {
  final int primaryColor;
  final int accentColor;
  final int brightness;
  final ThemeType theme;
  final String language;
  final bool smsEnabled;
  final bool notificationsEnabled;

  const SettingsStore({
    this.primaryColor = PRIMARY,
    this.accentColor = ACCENT,
    this.brightness = 0,
    this.theme = ThemeType.LIGHT,
    this.language = 'English',
    this.smsEnabled = false,
    this.notificationsEnabled = false,
  });

  @override
  int get hashCode => theme.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsStore &&
          runtimeType == other.runtimeType &&
          theme == other.theme;

  Map toJson() {
    return {
      "theme": theme.index,
      "primary": primaryColor,
      "accent": accentColor,
      "brightness": brightness
    };
  }

  static SettingsStore fromJson(dynamic json) {
    if (json == null) {
      return SettingsStore();
    }
    return SettingsStore(
      theme: ThemeType.values[json['theme']],
    );
  }

  @override
  String toString() {
    return '{theme: $theme}';
  }
}
