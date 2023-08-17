import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syphon/domain/settings/chat-settings/chat-lists/model.dart';
import 'package:syphon/domain/settings/devices-settings/model.dart';
import 'package:syphon/domain/settings/models.dart';
import 'package:syphon/domain/settings/notification-settings/model.dart';
import 'package:syphon/domain/settings/privacy-settings/model.dart';
import 'package:syphon/domain/settings/storage-settings/model.dart';
import 'package:syphon/domain/settings/theme-settings/model.dart';

import './chat-settings/model.dart';
import 'proxy-settings/model.dart';

part 'state.g.dart';

@JsonSerializable()
class SettingsStore extends Equatable {
  @JsonKey(includeFromJson: false, includeToJson: false)
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
  final ProxySettings proxySettings;
  final ThemeSettings themeSettings;
  final StorageSettings storageSettings;
  final PrivacySettings privacySettings;
  final Map<String, ChatSetting> chatSettings; // roomId
  final NotificationSettings notificationSettings;

  @JsonKey(includeFromJson: false, includeToJson: false)
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
    this.alphaAgreement,
    this.readReceipts = ReadReceiptTypes.Off,
    this.themeSettings = const ThemeSettings(),
    this.proxySettings = const ProxySettings(),
    this.privacySettings = const PrivacySettings(),
    this.storageSettings = const StorageSettings(),
    this.notificationSettings = const NotificationSettings(),
    this.pusherToken,
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
    bool? loading,
    String? alphaAgreement,
    String? pusherToken, // NOTE: device token for APNS
    ReadReceiptTypes? readReceipts,
    List<Device>? devices,
    List<ChatList>? chatLists,
    ThemeSettings? themeSettings,
    ProxySettings? proxySettings,
    PrivacySettings? privacySettings,
    StorageSettings? storageSettings,
    Map<String, ChatSetting>? chatSettings,
    NotificationSettings? notificationSettings,
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
        chatLists: chatLists ?? this.chatLists,
        loading: loading ?? this.loading,
        alphaAgreement: alphaAgreement ?? this.alphaAgreement,
        pusherToken: pusherToken ?? this.pusherToken,
        devices: devices ?? this.devices,
        readReceipts: readReceipts ?? this.readReceipts,
        chatSettings: chatSettings ?? this.chatSettings,
        themeSettings: themeSettings ?? this.themeSettings,
        proxySettings: proxySettings ?? this.proxySettings,
        privacySettings: privacySettings ?? this.privacySettings,
        storageSettings: storageSettings ?? this.storageSettings,
        notificationSettings: notificationSettings ?? this.notificationSettings,
      );

  Map<String, dynamic> toJson() => _$SettingsStoreToJson(this);

  factory SettingsStore.fromJson(Map<String, dynamic> json) => _$SettingsStoreFromJson(json);
}
