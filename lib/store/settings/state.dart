import 'package:syphon/global/colours.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';
import "package:syphon/global/themes.dart";
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
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
  final bool enterSend; // TODO: rename *enabled

  @HiveField(5)
  final bool readReceipts; // TODO: rename *enabled
  @HiveField(6)
  final bool typingIndicators; // TODO: rename *enabled
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
  final List<Device> devices;

  @HiveField(13)
  final NotificationSettings notificationSettings;

  @HiveField(14)
  final String alphaAgreement; // a timestamp of agreement for alpha TOS

  final String pusherToken; // NOTE: can be device token for APNS

  // Temporary
  final bool loading;

  const SettingsStore({
    this.primaryColor = Colours.cyanSyphon,
    this.accentColor = Colours.cyanSyphon,
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
    this.loading = false,
    this.notificationSettings,
    this.alphaAgreement,
    this.pusherToken,
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
        notificationSettings,
        alphaAgreement,
        pusherToken,
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
    NotificationSettings notificationSettings,
    List<Device> devices,
    bool loading,
    String alphaAgreement,
    String pusherToken, // NOTE: device token for APNS
  }) {
    return SettingsStore(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
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
      notificationSettings: notificationSettings ?? this.notificationSettings,
      devices: devices ?? this.devices,
      loading: loading ?? this.loading,
      alphaAgreement: alphaAgreement ?? this.alphaAgreement,
      pusherToken: pusherToken ?? this.pusherToken,
    );
  }
}
