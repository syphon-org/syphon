import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:syphon/global/colours.dart';
import 'package:syphon/store/settings/notification-settings/options/types.dart';

part 'model.g.dart';

enum LastUpdateType {
  Message,
  State,
}

///
/// Chat Setting (not plural)
///
/// TODO:
/// convert to "ChatSetting(s)" and make chat specific
/// customizations nested within a customChats object
///
@JsonSerializable()
class ChatSetting extends Equatable {
  final String roomId;
  final int primaryColor;
  final bool smsEnabled;
  final String language;

  final NotificationOptions? notificationOptions;

  final int messagesSelfDestructAfter;

  const ChatSetting({
    required this.roomId,
    this.language = 'English',
    this.smsEnabled = false,
    this.primaryColor = Colours.greyDefault,
    this.notificationOptions,
    this.messagesSelfDestructAfter = 0,
  });

  @override
  List<Object?> get props => [
        roomId,
        primaryColor,
        smsEnabled,
        language,
        notificationOptions,
        messagesSelfDestructAfter,
      ];

  ChatSetting copyWith({
    String? roomId,
    String? language,
    bool? smsEnabled,
    int? primaryColor,
    NotificationOptions? notificationOptions,
    int? messagesSelfDestructAfter,
  }) =>
      ChatSetting(
        roomId: roomId ?? this.roomId,
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        primaryColor: primaryColor ?? this.primaryColor,
        notificationOptions: notificationOptions ?? this.notificationOptions,
        messagesSelfDestructAfter: messagesSelfDestructAfter ?? this.messagesSelfDestructAfter,
      );
  Map<String, dynamic> toJson() => _$ChatSettingToJson(this);

  factory ChatSetting.fromJson(Map<String, dynamic> json) => _$ChatSettingFromJson(json);
}
