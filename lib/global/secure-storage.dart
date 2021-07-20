import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';

class SecureStorage {
  static FlutterSecureStorage? instance;

  Future<String?> read({required String key}) async {
    // mobile
    if (Platform.isAndroid || Platform.isIOS) {
      final storage = instance!;

      // try to read key
      try {
        return storage.read(key: key);
      } catch (error) {
        printError('[SecureStorage.read] $key $error');
        throw error;
      }
    }

    // desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // try to read key
      try {
        final directory = await getApplicationSupportDirectory();
        return await File(join(directory.path, key)).readAsString();
      } catch (error) {
        printError('[SecureStorage.read] $key $error');
        throw error;
      }
    }

    return null;
  }

  Future write({required String key, required String? value}) async {
    // mobile
    if (Platform.isAndroid || Platform.isIOS) {
      final storage = instance!;

      try {
        return storage.write(key: key, value: value);
      } catch (error) {
        printError('[SecureStorage.write] $error');
        throw error;
      }
    }

    // desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        final directory = await getApplicationSupportDirectory();
        await File(join(directory.path, key)).writeAsString(key, flush: true);
      } catch (error) {
        printError('[SecureStorage.write] $key $error');
        throw error;
      }
    }
  }

  Future delete({required String key}) async {
    // mobile
    if (Platform.isAndroid || Platform.isIOS) {
      final storage = instance!;

      try {
        return storage.delete(key: key);
      } catch (error) {
        printError('[SecureStorage.write] $error');
        throw error;
      }
    }

    // desktop
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      try {
        final directory = await getApplicationSupportDirectory();
        await File(join(directory.path, key)).delete();
      } catch (error) {
        printError('[SecureStorage.write] $key $error');
        throw error;
      }
    }
  }
}
