// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/store/settings/chat-settings/sort-order/model.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import './chat-settings/model.dart';

part 'state.g.dart';

@JsonSerializable()
class SettingsStore extends Equatable {
  @JsonKey(ignore: true)
  final bool loading;

  final bool enterSend; // TODO: rename *enabled
  final bool smsEnabled;
  final bool readReceipts; // TODO: rename *enabled
  final bool typingIndicators; // TODO: rename *enabled
  final bool notificationsEnabled;
  final bool membershipEventsEnabled;
  final bool roomTypeBadgesEnabled;
  final bool timeFormat24Enabled;
  final bool dismissKeyboardEnabled;

  final String language;

  final List<Device> devices;

  // Map<roomId, ChatSetting>
  final Map<String, ChatSetting>? customChatSettings;
  final List<String> sortGroups;
  final String? sortOrder;

  final NotificationSettings? notificationSettings;

  final AppTheme appTheme;

  final String? alphaAgreement; // a timestamp of agreement for alpha TOS

  @JsonKey(ignore: true)
  final String? pusherToken; // NOTE: can be device token for APNS

  const SettingsStore({
    this.language = 'English',
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
    this.appTheme = const AppTheme(),
    this.alphaAgreement,
    this.pusherToken,
  });

  @override
  List<Object?> get props => [
        language,
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
        appTheme,
        alphaAgreement,
        pusherToken,
      ];

  SettingsStore copyWith({
    String? language,
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
    AppTheme? appTheme,
    List<Device>? devices,
    bool? loading,
    String? alphaAgreement,
    String? pusherToken, // NOTE: device token for APNS
  }) =>
      SettingsStore(
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        enterSend: enterSend != null ? enterSend : this.enterSend,
        readReceipts: readReceipts != null ? readReceipts : this.readReceipts,
        typingIndicators:
            typingIndicators != null ? typingIndicators : this.typingIndicators,
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
        appTheme: appTheme ?? this.appTheme,
        devices: devices ?? this.devices,
        loading: loading ?? this.loading,
        alphaAgreement: alphaAgreement ?? this.alphaAgreement,
        pusherToken: pusherToken ?? this.pusherToken,
      );

  Map<String, dynamic> toJson() => _$SettingsStoreToJson(this);

  factory SettingsStore.fromJson(Map<String, dynamic> json) =>
      _$SettingsStoreFromJson(json);
}
