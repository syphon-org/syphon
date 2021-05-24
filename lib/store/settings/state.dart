// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/store/settings/chat-settings/sort-order/model.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import './chat-settings/model.dart';

part 'state.g.dart';

@JsonSerializable()
class SettingsStore extends Equatable {
  @JsonKey(ignore: true)
  final bool loading;

  final int? primaryColor;
  final int? accentColor;
  final int? appBarColor;
  final int? brightness;
  final ThemeType theme;

  final bool enterSend; // TODO: rename *enabled
  final bool smsEnabled;
  final bool readReceipts; // TODO: rename *enabled
  final bool typingIndicators; // TODO: rename *enabled
  final bool notificationsEnabled;
  final bool membershipEventsEnabled;
  final bool roomTypeBadgesEnabled;
  final bool timeFormat24Enabled;
  final bool dismissKeyboardEnabled;

  final String fontName;
  final String fontSize;
  final String language;
  final String avatarShape;
  final String messageSize;

  final List<Device> devices;

  // Map<roomId, ChatSetting>
  final Map<String, ChatSetting>? customChatSettings;
  final List<String> sortGroups;
  final String? sortOrder;

  final NotificationSettings? notificationSettings;

  final String? alphaAgreement; // a timestamp of agreement for alpha TOS

  @JsonKey(ignore: true)
  final String? pusherToken; // NOTE: can be device token for APNS

  const SettingsStore({
    this.primaryColor = Colours.cyanSyphon,
    this.accentColor = Colours.cyanSyphon,
    this.appBarColor,
    this.brightness = 0,
    this.theme = ThemeType.LIGHT,
    this.fontName = 'Rubik',
    this.fontSize = 'Default',
    this.messageSize = 'Default',
    this.language = 'English',
    this.avatarShape = 'Circle',
    this.sortGroups = const [SortOptions.PINNED],
    this.sortOrder = SortOrder.LATEST,
    this.enterSend = false,
    this.smsEnabled = false,
    this.readReceipts = false,
    this.typingIndicators = false,
    this.notificationsEnabled = false,
    this.membershipEventsEnabled = true,
    this.roomTypeBadgesEnabled = true,
    this.timeFormat24Enabled = false,
    this.dismissKeyboardEnabled = false,
    this.customChatSettings,
    this.devices = const [],
    this.loading = false,
    this.notificationSettings,
    this.alphaAgreement,
    this.pusherToken,
  });

  @override
  List<Object?> get props => [
        primaryColor,
        accentColor,
        appBarColor,
        brightness,
        theme,
        fontName,
        fontSize,
        messageSize,
        language,
        avatarShape,
        smsEnabled,
        enterSend,
        readReceipts,
        typingIndicators,
        notificationsEnabled,
        roomTypeBadgesEnabled,
        timeFormat24Enabled,
        dismissKeyboardEnabled,
        customChatSettings,
        devices,
        loading,
        notificationSettings,
        alphaAgreement,
        pusherToken,
      ];

  SettingsStore copyWith({
    int? primaryColor,
    int? accentColor,
    int? appBarColor,
    int? brightness,
    ThemeType? theme,
    String? fontName,
    String? fontSize,
    String? language,
    String? messageSize,
    String? avatarShape,
    bool? smsEnabled,
    bool? enterSend,
    bool? readReceipts,
    bool? typingIndicators,
    bool? notificationsEnabled,
    bool? membershipEventsEnabled,
    bool? roomTypeBadgesEnabled,
    bool? timeFormat24Enabled,
    bool? dismissKeyboardEnabled,
    Map<String, ChatSetting>? customChatSettings,
    NotificationSettings? notificationSettings,
    List<Device>? devices,
    bool? loading,
    String? alphaAgreement,
    String? pusherToken, // NOTE: device token for APNS
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
        enterSend: enterSend ?? this.enterSend,
        readReceipts: readReceipts ?? this.readReceipts,
        typingIndicators:
            typingIndicators ?? this.typingIndicators,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        timeFormat24Enabled: timeFormat24Enabled ?? this.timeFormat24Enabled,
        dismissKeyboardEnabled:
            dismissKeyboardEnabled ?? this.dismissKeyboardEnabled,
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
        messageSize: messageSize ?? this.messageSize,
      );

  Map<String, dynamic> toJson() => _$SettingsStoreToJson(this);

  factory SettingsStore.fromJson(Map<String, dynamic> json) =>
      _$SettingsStoreFromJson(json);
}
