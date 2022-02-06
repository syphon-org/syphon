import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/store/settings/chat-settings/chat-lists/model.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/models.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';

import './chat-settings/model.dart';
import 'proxy-settings/model.dart';

part 'state.g.dart';

@JsonSerializable()
class SettingsStore extends Equatable {
  @JsonKey(ignore: true)
  final bool loading;

  final String language;
  final String? alphaAgreement; // a timestamp of agreement for alpha TOS

  final bool smsEnabled;
  final bool enterSendEnabled;
  final bool autocorrectEnabled;
  final bool suggestionsEnabled;
  final bool typingIndicatorsEnabled;
  final bool membershipEventsEnabled;
  final bool roomTypeBadgesEnabled;
  final bool timeFormat24Enabled;
  final bool dismissKeyboardEnabled;
  final bool autoDownloadEnabled;

  final int syncInterval;
  final int syncPollTimeout;

  final SortOrder globalSortOrder;
  final List<ChatList> chatLists;
  final ReadReceiptTypes readReceipts;

  final List<Device> devices;
  final ThemeSettings themeSettings;
  final Map<String, ChatSetting> chatSettings; // roomId
  final NotificationSettings notificationSettings;

  final ProxySettings proxySettings;

  @JsonKey(ignore: true)
  final String? pusherToken; // NOTE: can be device token for APNS

  const SettingsStore({
    this.language = '',
    this.syncInterval = 2000, // millis
    this.syncPollTimeout = 10000, // millis
    this.chatLists = const [],
    this.globalSortOrder = SortOrder.Latest,
    this.enterSendEnabled = false,
    this.autocorrectEnabled = false,
    this.suggestionsEnabled = false,
    this.smsEnabled = false,
    this.typingIndicatorsEnabled = false,
    this.membershipEventsEnabled = true,
    this.roomTypeBadgesEnabled = true,
    this.timeFormat24Enabled = false,
    this.dismissKeyboardEnabled = false,
    this.autoDownloadEnabled = false,
    this.chatSettings = const <String, ChatSetting>{},
    this.devices = const [],
    this.loading = false,
    this.notificationSettings = const NotificationSettings(),
    this.themeSettings = const ThemeSettings(),
    this.alphaAgreement,
    this.pusherToken,
    this.readReceipts = ReadReceiptTypes.Off,
    this.proxySettings = const ProxySettings(),
  });

  @override
  List<Object?> get props => [
        language,
        smsEnabled,
        enterSendEnabled,
        autocorrectEnabled,
        suggestionsEnabled,
        typingIndicatorsEnabled,
        roomTypeBadgesEnabled,
        timeFormat24Enabled,
        dismissKeyboardEnabled,
        autoDownloadEnabled,
        chatSettings,
        chatLists,
        devices,
        loading,
        notificationSettings,
        themeSettings,
        alphaAgreement,
        pusherToken,
        readReceipts,
        proxySettings,
      ];

  SettingsStore copyWith({
    String? language,
    bool? smsEnabled,
    bool? enterSendEnabled,
    bool? autocorrectEnabled,
    bool? suggestionsEnabled,
    bool? typingIndicatorsEnabled,
    bool? membershipEventsEnabled,
    bool? roomTypeBadgesEnabled,
    bool? timeFormat24Enabled,
    bool? dismissKeyboardEnabled,
    bool? autoDownloadEnabled,
    int? syncInterval,
    int? syncPollTimeout,
    Map<String, ChatSetting>? chatSettings,
    NotificationSettings? notificationSettings,
    ThemeSettings? themeSettings,
    List<Device>? devices,
    List<ChatList>? chatLists,
    bool? loading,
    String? alphaAgreement,
    String? pusherToken, // NOTE: device token for APNS
    ReadReceiptTypes? readReceipts,
    ProxySettings? proxySettings,
  }) =>
      SettingsStore(
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        enterSendEnabled: enterSendEnabled ?? this.enterSendEnabled,
        autocorrectEnabled: autocorrectEnabled ?? this.autocorrectEnabled,
        suggestionsEnabled: suggestionsEnabled ?? this.suggestionsEnabled,
        typingIndicatorsEnabled: typingIndicatorsEnabled ?? this.typingIndicatorsEnabled,
        timeFormat24Enabled: timeFormat24Enabled ?? this.timeFormat24Enabled,
        dismissKeyboardEnabled: dismissKeyboardEnabled ?? this.dismissKeyboardEnabled,
        membershipEventsEnabled: membershipEventsEnabled ?? this.membershipEventsEnabled,
        roomTypeBadgesEnabled: roomTypeBadgesEnabled ?? this.roomTypeBadgesEnabled,
        autoDownloadEnabled: autoDownloadEnabled ?? this.autoDownloadEnabled,
        syncInterval: syncInterval ?? this.syncInterval,
        syncPollTimeout: syncPollTimeout ?? this.syncPollTimeout,
        chatSettings: chatSettings ?? this.chatSettings,
        chatLists: chatLists ?? this.chatLists,
        notificationSettings: notificationSettings ?? this.notificationSettings,
        themeSettings: themeSettings ?? this.themeSettings,
        devices: devices ?? this.devices,
        loading: loading ?? this.loading,
        alphaAgreement: alphaAgreement ?? this.alphaAgreement,
        pusherToken: pusherToken ?? this.pusherToken,
        readReceipts: readReceipts ?? this.readReceipts,
        proxySettings: proxySettings ?? this.proxySettings,
      );

  Map<String, dynamic> toJson() => _$SettingsStoreToJson(this);

  factory SettingsStore.fromJson(Map<String, dynamic> json) => _$SettingsStoreFromJson(json);
}
