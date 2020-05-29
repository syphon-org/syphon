import 'package:Tether/global/colors.dart';
import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: ChatSettingsHiveId)
class ChatSetting extends Equatable {
  @HiveField(0)
  final String roomId;
  @HiveField(1)
  final int primaryColor;
  @HiveField(2)
  final bool smsEnabled;
  @HiveField(3)
  final bool notificationsEnabled;
  @HiveField(4)
  final String language;

  const ChatSetting({
    this.roomId,
    this.language = 'English',
    this.smsEnabled = false,
    this.primaryColor = GREY_DEFAULT,
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
}
