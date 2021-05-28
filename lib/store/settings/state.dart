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

  final bool smsEnabled;
  final bool enterSendEnabled;
  final bool readReceiptsEnabled;
  final bool typingIndicatorsEnabled;
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

  final int syncInterval;
  final int syncPollTimeout;

  final String sortOrder;
  final List<String> sortGroups;

  final List<Device> devices;
  final NotificationSettings notificationSettings;
  final Map<String, ChatSetting> chatSettings; // roomId

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
    this.syncInterval = 2000, // millis
    this.syncPollTimeout = 10000, // millis
    this.sortGroups = const [SortOptions.PINNED],
    this.sortOrder = SortOrder.LATEST,
    this.enterSendEnabled = false,
    this.smsEnabled = false,
    this.readReceiptsEnabled = false,
    this.typingIndicatorsEnabled = false,
    this.notificationsEnabled = false,
    this.membershipEventsEnabled = true,
    this.roomTypeBadgesEnabled = true,
    this.timeFormat24Enabled = false,
    this.dismissKeyboardEnabled = false,
    this.chatSettings = const <String, ChatSetting>{},
    this.devices = const [],
    this.loading = false,
    this.notificationSettings = const NotificationSettings(),
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
        enterSendEnabled,
        readReceiptsEnabled,
        typingIndicatorsEnabled,
        notificationsEnabled,
        roomTypeBadgesEnabled,
        timeFormat24Enabled,
        dismissKeyboardEnabled,
        chatSettings,
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
    bool? enterSendEnabled,
    bool? readReceiptsEnabled,
    bool? typingIndicatorsEnabled,
    bool? notificationsEnabled,
    bool? membershipEventsEnabled,
    bool? roomTypeBadgesEnabled,
    bool? timeFormat24Enabled,
    bool? dismissKeyboardEnabled,
    int? syncInterval,
    Map<String, ChatSetting>? chatSettings,
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
        enterSendEnabled: enterSendEnabled ?? this.enterSendEnabled,
        readReceiptsEnabled: readReceiptsEnabled ?? this.readReceiptsEnabled,
        typingIndicatorsEnabled:
            typingIndicatorsEnabled ?? this.typingIndicatorsEnabled,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        timeFormat24Enabled: timeFormat24Enabled ?? this.timeFormat24Enabled,
        dismissKeyboardEnabled:
            dismissKeyboardEnabled ?? this.dismissKeyboardEnabled,
        membershipEventsEnabled:
            membershipEventsEnabled ?? this.membershipEventsEnabled,
        roomTypeBadgesEnabled:
            roomTypeBadgesEnabled ?? this.roomTypeBadgesEnabled,
        syncInterval: syncInterval ?? this.syncInterval,
        chatSettings: chatSettings ?? this.chatSettings,
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
