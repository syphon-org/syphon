enum MembershipEventTypes {
  invite,
  join,
  leave,
  ban,
  knock,
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
