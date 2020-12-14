// Package imports:
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

// Project imports:
import 'package:syphon/global/colours.dart';

part 'model.g.dart';

@JsonSerializable()
class ChatSetting extends Equatable {
  final String roomId;
  final int primaryColor;
  final bool smsEnabled;
  final bool notificationsEnabled;
  final String language;

  const ChatSetting({
    this.roomId,
    this.language = 'English',
    this.smsEnabled = false,
    this.primaryColor = Colours.greyDefault,
    this.notificationsEnabled = false,
  });

  @override
  List<Object> get props => [
        roomId,
        primaryColor,
        smsEnabled,
        notificationsEnabled,
        language,
      ];

  ChatSetting copyWith({
    String roomId,
    String language,
    bool smsEnabled,
    int primaryColor,
    bool notificationsEnabled,
  }) =>
      ChatSetting(
        roomId: roomId ?? this.roomId,
        language: language ?? this.language,
        smsEnabled: smsEnabled ?? this.smsEnabled,
        primaryColor: primaryColor ?? this.primaryColor,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      );
  Map<String, dynamic> toJson() => _$ChatSettingToJson(this);

  factory ChatSetting.fromJson(Map<String, dynamic> json) =>
      _$ChatSettingFromJson(json);
}
