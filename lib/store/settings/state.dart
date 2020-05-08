import 'package:Tether/global/colors.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import "package:Tether/global/themes.dart";
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import './chat-settings/model.dart';

part 'state.g.dart';

@HiveType(typeId: SettingsStoreHiveId)
class SettingsStore extends Equatable {
  @HiveField(0)
  final int primaryColor;
  @HiveField(1)
  final int accentColor;
  @HiveField(2)
  final int brightness;
  @HiveField(3)
  final bool smsEnabled;
  @HiveField(4)
  final bool enterSend;

  @HiveField(5)
  final bool readReceipts; // on / off
  @HiveField(6)
  final bool typingIndicators; // on / off
  @HiveField(7)
  final bool notificationsEnabled;
  @HiveField(8)
  final bool membershipEventsEnabled;
  @HiveField(9)
  final String language;

  @HiveField(10)
  final ThemeType theme;

  // mapped by roomId
  @HiveField(11)
  final Map<String, ChatSetting> customChatSettings;

  @HiveField(12)
  final List<DeviceSetting> devices;

  // Temporary
  final bool loading;

  const SettingsStore({
    this.primaryColor = TETHERED_CYAN,
    this.accentColor = TETHERED_CYAN,
    this.brightness = 0,
    this.theme = ThemeType.LIGHT,
    this.language = 'English',
    this.enterSend = false,
    this.smsEnabled = false,
    this.readReceipts = false,
    this.typingIndicators = false,
    this.notificationsEnabled = false,
    this.membershipEventsEnabled = true,
    this.customChatSettings,
    this.devices = const [],
    this.loading,
  });

  @override
  List<Object> get props => [
        primaryColor,
        accentColor,
        brightness,
        theme,
        language,
        smsEnabled,
        enterSend,
        readReceipts,
        typingIndicators,
        notificationsEnabled,
        customChatSettings,
        devices,
        loading,
      ];

  SettingsStore copyWith({
    int primaryColor,
    int accentColor,
    int brightness,
    ThemeType theme,
    String language,
    bool smsEnabled,
    bool enterSend,
    bool readReceipts,
    bool typingIndicators,
    bool notificationsEnabled,
    bool membershipEventsEnabled,
    Map<String, ChatSetting> customChatSettings,
    List<DeviceSetting> devices,
    bool loading,
  }) {
    return SettingsStore(
      primaryColor: primaryColor,
      accentColor: accentColor,
      brightness: brightness ?? this.brightness,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      enterSend: enterSend != null ? enterSend : this.enterSend,
      readReceipts: readReceipts != null ? readReceipts : this.readReceipts,
      typingIndicators:
          typingIndicators != null ? typingIndicators : this.typingIndicators,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      membershipEventsEnabled:
          membershipEventsEnabled ?? this.membershipEventsEnabled,
      customChatSettings: customChatSettings ?? this.customChatSettings,
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
    );
  }
}
