import 'package:Tether/global/colors.dart';
import 'package:dart_json_mapper/dart_json_mapper.dart';

@jsonSerializable
class ChatSetting {
  final String roomId;
  final int primaryColor;
  final bool smsEnabled;
  final bool notificationsEnabled;
  final String language;

  const ChatSetting({
    this.roomId,
    this.language = 'English',
    this.smsEnabled = false,
    this.primaryColor = TETHERED_CYAN,
    this.notificationsEnabled = false,
  });

  ChatSetting copyWith({
    String roomId,
    String language,
    bool smsEnabled,
    int primaryColor,
    bool notificationsEnabled,
  }) {
    return ChatSetting(
      roomId: roomId ?? this.roomId,
      language: language ?? this.language,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      primaryColor: primaryColor ?? this.primaryColor,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  int get hashCode =>
      roomId.hashCode ^
      language.hashCode ^
      smsEnabled.hashCode ^
      primaryColor.hashCode ^
      notificationsEnabled.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSetting &&
          runtimeType == other.runtimeType &&
          roomId == other.roomId &&
          language == other.language &&
          smsEnabled == other.smsEnabled &&
          primaryColor == other.primaryColor &&
          notificationsEnabled == other.notificationsEnabled;
}
