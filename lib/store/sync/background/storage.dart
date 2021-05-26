import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syphon/cache/index.dart';

///
/// Save Crypto Store
///
/// Save the crypto store to cold storage
/// Idealy, run this after performance a pure action
Future saveRoomNames({required Map<String, String> roomNames}) async {
  // Try to pull new lastSince if available
  try {
    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(
      key: Cache.roomNamesKey,
      value: jsonEncode(roomNames),
    );
  } catch (error) {
    print('[saveRoomNames] ${error.toString()}');
  }
}

///
/// Load Crypto (Cold Storage)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<Map<String, String>> loadRoomNames() async {
  try {
    final secureStorage = FlutterSecureStorage();

    return await jsonDecode(
      await secureStorage.read(key: Cache.roomNamesKey) ?? '{}',
    );
  } catch (error) {
    print('[loadRoomNames] ${error.toString()}');
  }

  return {};
}

///
/// Save Last Since
///
/// Save the crypto store to cold storage
/// Idealy, run this after performance a pure action
Future saveLastSince({required String lastSince}) async {
  // Try to pull new lastSince if available
  try {
    if (lastSince.isEmpty) return;

    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(key: Cache.lastSinceKey, value: lastSince);
  } catch (error) {
    print('[saveLastSince] ${error.toString()}');
  }
}

///
/// Load Crypto (Cold Storage)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<String> loadLastSince({required String fallback}) async {
  try {
    final secureStorage = FlutterSecureStorage();

    return await secureStorage.read(key: Cache.lastSinceKey) ?? fallback;
  } catch (error) {
    print('[loadLastSince] ${error.toString()}');
  }

  return fallback;
}
