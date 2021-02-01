/**
 * Event Models and Types
 *  
 * https://matrix.org/docs/spec/client_server/latest#m-room-message-msgtypes
 */
class AccountDataTypes {
  static const direct = 'm.direct';
  static const presence = 'm.presence';
  static const ignoredUserList = 'm.ignored_user_list';
}

class RelationTypes {
  static const relatesTo = 'm.relates_to';
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

  static const guestAccess = 'm.room.guest_access';
  static const joinRules = 'm.room.join_rules';
  static const historyVisibility = 'm.room.history_visibility';
  static const powerLevels = 'm.room.power_levels';
  static const encryption = 'm.room.encryption';
  static const roomKey = 'm.room_key';
}

class MessageTypes {
  static const TEXT = 'm.text';
  static const EMOTE = 'm.emote';
  static const NOTICE = 'm.notice';
  static const IMAGE = 'm.text';
  static const FILE = 'm.file';
  static const AUDIO = 'm.text';
  static const LOCATION = 'm.location';
  static const VIDEO = 'm.video';
}

class MediumType {
  static const sms = 'sms';
  static const direct = 'direct';
  static const plaintext = 'plaintext';
  static const encryption = 'encryption';
}
