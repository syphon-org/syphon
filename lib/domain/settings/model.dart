import 'package:Tether/global/colors.dart';
import "package:Tether/global/themes.dart";
import './chat-settings/model.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class SettingsStore {
  final int primaryColor;
  final int accentColor;
  final int brightness;
  final bool smsEnabled;
  final bool notificationsEnabled;
  final String language;

  @JsonProperty(enumValues: ThemeType.values)
  final ThemeType theme;

  final Map<String, ChatSetting> customChatSettings;

  const SettingsStore({
    this.primaryColor = TETHERED_CYAN,
    this.accentColor = BESIDES_BLUE,
    this.brightness = 0,
    this.theme = ThemeType.LIGHT,
    this.language = 'English',
    this.smsEnabled = false,
    this.notificationsEnabled = false,
    this.customChatSettings,
  });

  SettingsStore copyWith({
    int primaryColor,
    int accentColor,
    int brightness,
    ThemeType theme,
    String language,
    bool smsEnabled,
    bool notificationsEnabled,
  }) {
    return SettingsStore(
      primaryColor: primaryColor,
      accentColor: accentColor,
      brightness: brightness ?? this.brightness,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      customChatSettings: customChatSettings ?? this.customChatSettings,
    );
  }

  @override
  int get hashCode =>
      primaryColor.hashCode ^
      accentColor.hashCode ^
      brightness.hashCode ^
      theme.hashCode ^
      language.hashCode ^
      smsEnabled.hashCode ^
      notificationsEnabled.hashCode ^
      customChatSettings.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsStore &&
          runtimeType == other.runtimeType &&
          primaryColor == other.primaryColor &&
          accentColor == other.accentColor &&
          brightness == other.brightness &&
          theme == other.theme &&
          language == other.language &&
          smsEnabled == other.smsEnabled &&
          notificationsEnabled == other.notificationsEnabled &&
          customChatSettings == other.customChatSettings;

  // Map toJson() {
  //   return {
  //     "theme": theme.index,
  //     "primary": primaryColor,
  //     "accent": accentColor,
  //     "brightness": brightness
  //   };
  // }

  // static SettingsStore fromJson(dynamic json) {
  //   if (json == null) {
  //     return SettingsStore();
  //   }
  //   return SettingsStore(
  //     theme: ThemeType.values[json['theme']],
  //   );
  // }

  // @override
  // String toString() {
  //   return '{theme: $theme}';
  // }
}
