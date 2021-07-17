import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:encrypt/encrypt.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';

class KeyStorage {
// Global hot cache storage reference to prevent redundent storage loading
  static FlutterSecureStorage? keyStorage;
}

String generateKey() {
  return Key.fromSecureRandom(32).base64;
}

Future<String?> loadKey(String keyId) async {
  var key;

  // mobile
  if (Platform.isAndroid || Platform.isIOS) {
    final keyStorage = KeyStorage.keyStorage!;

    // try to read key
    try {
      key = await keyStorage.read(key: keyId);
    } catch (error) {
      printError('[loadKey] $error');
    }

    // generate a new one on failure
    if (key == null) {
      key = generateKey();
      await keyStorage.write(key: keyId, value: key);
    }
  }

  // desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    // try to read key
    try {
      final directory = await getApplicationSupportDirectory();
      key = await File(join(directory.path, keyId)).readAsString();
    } catch (error) {
      printError('[loadKey] $error');
    }

    // generate a new one on failure
    try {
      if (key == null) {
        final directory = await getApplicationSupportDirectory();
        key = generateKey();
        await File(join(directory.path, keyId)).writeAsString(key, flush: true);
      }
    } catch (error) {
      printError('[loadKey] $error');
    }
  }

  return key;
}
