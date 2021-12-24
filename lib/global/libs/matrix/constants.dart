/// Event Models and Types
///
/// https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
class AccountDataTypes {
  static const direct = 'm.direct';
  static const presence = 'm.presence';
  static const ignoredUserList = 'm.ignored_user_list';
}

class RelationTypes {
  static const annotation = 'm.annotation';
  static const replace = 'm.replace';
}

class EventTypes {
  static const name = 'm.room.name';
  static const topic = 'm.room.topic';
  static const avatar = 'm.room.avatar';
  static const creation = 'm.room.create';
  static const message = 'm.room.message';
  static const encrypted = 'm.room.encrypted';
  static const member = 'm.room.member';
  static const redaction = 'm.room.redaction';
  static const reaction = 'm.reaction';

  static const callInvite = 'm.call.invite';
  static const callCandidates = 'm.call.candidates';
  static const callHangup = 'm.call.hangup';

  static const guestAccess = 'm.room.guest_access';
  static const joinRules = 'm.room.join_rules';
  static const historyVisibility = 'm.room.history_visibility';
  static const powerLevels = 'm.room.power_levels';
  static const encryption = 'm.room.encryption';
  static const roomKey = 'm.room_key';
  static const roomKeyRequest = 'm.room_key_request';
}

enum MessageType {
  text,
  emote,
  notice,
  image,
  file,
  audio,
  location,
  video,
}

class MatrixMessageTypes {
  static const text = 'm.text';
  static const emote = 'm.emote';
  static const notice = 'm.notice';
  static const image = 'm.image';
  static const file = 'm.file';
  static const audio = 'm.audio';
  static const location = 'm.location';
  static const video = 'm.video';
}

extension MatrixMessageType on MessageType {
  static String _value(MessageType val) {
    switch (val) {
      case MessageType.text:
        return MatrixMessageTypes.text;
      case MessageType.image:
        return MatrixMessageTypes.image;
      case MessageType.file:
        return MatrixMessageTypes.file;
    }
    return '';
  }

  String get value => _value(this);
}

class MediumType {
  static const sms = 'sms';
  static const direct = 'direct';
  static const plaintext = 'plaintext';
  static const encryption = 'encryption';
}
