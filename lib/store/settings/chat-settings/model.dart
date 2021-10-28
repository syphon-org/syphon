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

  const ChatSetting({
    required this.roomId,
    this.language = 'English',
    this.smsEnabled = false,
    this.primaryColor = Colours.greyDefault,
    this.notificationOptions,
  });

  @override
  List<Object?> get props => [
        roomId,
        primaryColor,
        smsEnabled,
        language,
        notificationOptions,
      ];

  ChatSetting copyWith({
    String? roomId,
    String? language,
    bool? smsEnabled,
    int? primaryColor,
    NotificationOptions? notificationOptions,
  }) =>
      ChatSetting(
        roomId: roomId ?? this.roomId,
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        primaryColor: primaryColor ?? this.primaryColor,
        notificationOptions: notificationOptions ?? this.notificationOptions,
      );
  Map<String, dynamic> toJson() => _$ChatSettingToJson(this);

  factory ChatSetting.fromJson(Map<String, dynamic> json) => _$ChatSettingFromJson(json);
}
