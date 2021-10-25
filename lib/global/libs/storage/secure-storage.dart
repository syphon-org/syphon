import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';

class SecureStorage {
  static FlutterSecureStorage? instance;

  static Future<bool> check({required String key}) async {
    try {
      printInfo('[SecureStorage.check] checking $key');
      // mobile
      if (Platform.isAndroid || Platform.isIOS) {
        // try to read key
        final storage = instance!;
        return storage.containsKey(key: key);
      }

      // desktop
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // try to read key
        final directory = await getApplicationSupportDirectory();
        return File(join(directory.path, key)).exists();
      }

      throw '[SecureStorage.check] Unsupported device error';
    } catch (error) {
      return false;
    }
  }

  Future<String?> read({required String key}) async {
    try {
      // mobile
      if (Platform.isAndroid || Platform.isIOS) {
        // try to read key
        final storage = instance!;
        return storage.read(key: key);
      }

      // desktop
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        // try to read key
        final directory = await getApplicationSupportDirectory();
        return File(join(directory.path, key)).readAsString();
      }
    } catch (error) {
      return null;
    }
  }

  Future write({required String key, required String value}) async {
    try {
      // mobile
      if (Platform.isAndroid || Platform.isIOS) {
        final storage = instance!;
        return storage.write(key: key, value: value);
      }

      // desktop
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final directory = await getApplicationSupportDirectory();
        await File(join(directory.path, key)).writeAsString(value, flush: true);
      }
    } catch (error) {
      return null;
    }
  }

  Future delete({required String key}) async {
    try {
      // mobile
      if (Platform.isAndroid || Platform.isIOS) {
        final storage = instance!;
        return storage.delete(key: key);
      }

      // desktop
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final directory = await getApplicationSupportDirectory();
        await File(join(directory.path, key)).delete();
      }
    } catch (error) {
      return null;
    }
  }
}
