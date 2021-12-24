///
/// Storage Keys
///
/// Keys to the castle or
/// just keys to reference data
/// from cold storage
class StorageKeys {
  static const String AUTH = 'auth';
  static const String ROOMS = 'rooms';
  static const String USERS = 'users';
  static const String MEDIA = 'media';
  static const String CRYPTO = 'crypto';
  static const String SETTINGS = 'settings';
  static const String EVENTS = 'events';
  static const String MESSAGES = 'messages';
  static const String DECRYPTED = 'decrypted';
  static const String RECEIPTS = 'receipts';
  static const String REACTIONS = 'reactions';
  static const String REDACTIONS = 'redactions';
}

enum StorageKey {
  check,
  auth,
  rooms,
  users,
  meida,
  crypto,
  settings,
  events,
  messages,
  decrypted,
  receipts,
  reactions,
  redactions
}

const int DEFAULT_LOAD_LIMIT = 25;
