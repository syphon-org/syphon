import 'dart:convert';

import 'package:syphon/global/libs/storage/secure-storage.dart';
import 'package:syphon/global/print.dart';

const KEY_BACKUP_PASSWORD_KEY = 'KEY_BACKUP_PASSWORD_KEY';

final _storage = SecureStorage();

Future<void> saveBackupPassword({required String password}) async {
  return _storage.write(
    key: KEY_BACKUP_PASSWORD_KEY,
    value: json.encode(password),
  );
}

Future<bool> checkBackupPassword() async {
  try {
    return await _storage.check(
      key: KEY_BACKUP_PASSWORD_KEY,
    );
  } catch (error) {
    log.error(error.toString());
    return false;
  }
}

Future<String> loadBackupPassword() async {
  try {
    return await _storage.read(key: KEY_BACKUP_PASSWORD_KEY) ?? '';
  } catch (error) {
    log.error(error.toString());
    return '';
  }
}
