// Package imports:
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

// Project imports:
import "package:syphon/global/themes.dart";
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import './chat-settings/model.dart';

part 'state.g.dart';

// Next Field ID: 21
@HiveType(typeId: SettingsStoreHiveId)
class SettingsStore extends Equatable {
  @HiveField(0)
  final int primaryColor;
  @HiveField(1)
  final int accentColor;
  @HiveField(15)
  final int appBarColor;
  @HiveField(2)
  final int brightness;
  @HiveField(10)
  final ThemeType theme;

  @HiveField(4)
  final bool enterSend; // TODO: rename *enabled
  @HiveField(3)
  final bool smsEnabled;
  @HiveField(5)
  final bool readReceipts; // TODO: rename *enabled
  @HiveField(6)
  final bool typingIndicators; // TODO: rename *enabled
  @HiveField(7)
  final bool notificationsEnabled;
  @HiveField(8)
  final bool membershipEventsEnabled;
  @HiveField(18)
  final bool roomTypeBadgesEnabled;
  @HiveField(19)
  final bool timeFormat24Enabled;

  @HiveField(16)
  final String fontName;
  @HiveField(17)
  final String fontSize;
  @HiveField(9)
  final String language;
  @HiveField(20)
  final String avatarShape;

  @HiveField(12)
  final List<Device> devices;
  // Map<roomId, ChatSetting>
  @HiveField(11)
  final Map<String, ChatSetting> customChatSettings;

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
    this.appBarColor,
    this.brightness = 0,
    this.theme = ThemeType.LIGHT,
    this.fontName = 'Rubik',
    this.fontSize = 'Default',
    this.language = 'English',
    this.avatarShape = 'Circle',
    this.enterSend = false,
    this.smsEnabled = false,
    this.readReceipts = false,
    this.typingIndicators = false,
    this.notificationsEnabled = false,
    this.membershipEventsEnabled = true,
    this.roomTypeBadgesEnabled = true,
    this.timeFormat24Enabled = false,
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
        appBarColor,
        brightness,
        theme,
        fontName,
        fontSize,
        language,
        avatarShape,
        smsEnabled,
        enterSend,
        readReceipts,
        typingIndicators,
        notificationsEnabled,
        roomTypeBadgesEnabled,
        timeFormat24Enabled,
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
    int appBarColor,
    int brightness,
    ThemeType theme,
    String fontName,
    String fontSize,
    String language,
    String avatarShape,
    bool smsEnabled,
    bool enterSend,
    bool readReceipts,
    bool typingIndicators,
    bool notificationsEnabled,
    bool membershipEventsEnabled,
    bool roomTypeBadgesEnabled,
    bool timeFormat24Enabled,
    Map<String, ChatSetting> customChatSettings,
    NotificationSettings notificationSettings,
    List<Device> devices,
    bool loading,
    String alphaAgreement,
    String pusherToken, // NOTE: device token for APNS
  }) =>
      SettingsStore(
        primaryColor: primaryColor ?? this.primaryColor,
        accentColor: accentColor ?? this.accentColor,
        appBarColor: appBarColor ?? this.appBarColor,
        brightness: brightness ?? this.brightness,
        theme: theme ?? this.theme,
        fontName: fontName ?? this.fontName,
        fontSize: fontSize ?? this.fontSize,
        language: language ?? this.language,
        avatarShape: avatarShape ?? this.avatarShape,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        enterSend: enterSend != null ? enterSend : this.enterSend,
        readReceipts: readReceipts != null ? readReceipts : this.readReceipts,
        typingIndicators:
            typingIndicators != null ? typingIndicators : this.typingIndicators,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        timeFormat24Enabled: timeFormat24Enabled ?? this.timeFormat24Enabled,
        membershipEventsEnabled:
            membershipEventsEnabled ?? this.membershipEventsEnabled,
        roomTypeBadgesEnabled:
            roomTypeBadgesEnabled ?? this.roomTypeBadgesEnabled,
        customChatSettings: customChatSettings ?? this.customChatSettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        devices: devices ?? this.devices,
        loading: loading ?? this.loading,
        alphaAgreement: alphaAgreement ?? this.alphaAgreement,
        pusherToken: pusherToken ?? this.pusherToken,
      );
}
