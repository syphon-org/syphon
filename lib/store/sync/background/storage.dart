import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/sync/background/service.dart';

///
/// Save Room Names (BackgroundSync)
///
/// Save the crypto store to cold storage
/// Idealy, run this after performance a pure action
Future saveRoomNames({required Map<String, String> roomNames}) async {
  // Try to pull new lastSince if available
  try {
    if (roomNames.isEmpty) return;

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
/// Load Room Names (BackgroundSync)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<Map<String, String>> loadRoomNames() async {
  FlutterSecureStorage secureStorage;

  try {
    secureStorage = FlutterSecureStorage();

    return Map<String, String>.from(await jsonDecode(
      await secureStorage.read(key: Cache.roomNamesKey) ?? '{}',
    ));
  } catch (error) {
    try {
      secureStorage = FlutterSecureStorage();
      secureStorage.delete(key: Cache.roomNamesKey);
    } catch (error) {}
    print('[loadRoomNames] ${error.toString()}');
  }

  return <String, String>{};
}

///
/// Load Last Since (BackgroundSync)
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
/// Load Crypto (BackgroundSync)
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

///
/// Save Notification Settings (BackgroundSync)
///
/// Used to update settings while the background
/// sync thread is currently running
///
Future saveNotificationSettings({NotificationSettings? settings}) async {
  // Try to pull new lastSince if available
  try {
    if (settings == null) return;

    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(
      key: BackgroundSync.notificationSettings,
      value: jsonEncode(settings),
    );
  } catch (error) {
    print('[saveNotificationSettings] ${error.toString()}');
  }
}

///
/// Load Notification Settings (BackgroundSync)
///
/// Used to load settings while the background
/// sync thread is currently running
///
Future<NotificationSettings> loadNotificationSettings(
    {NotificationSettings fallback = const NotificationSettings()}) async {
  try {
    final secureStorage = FlutterSecureStorage();

    final settingsEncoded = await secureStorage.read(
      key: BackgroundSync.notificationSettings,
    );

    final settingsJson = await jsonDecode(settingsEncoded!);

    return NotificationSettings.fromJson(settingsJson);
  } catch (error) {
    print('[loadNotificationSettings] ${error.toString()}');
  }

  return fallback;
}

///
/// Save Notification Data Unchecked (BackgroundSync)
///
/// Used to save unchecked notification data when
/// the notification style is Inbox. Aggregates all unchecked
/// notifications into one.
///
Future saveNotificationsUnchecked(Map<String, String> uncheckedMessages) async {
  try {
    final secureStorage = FlutterSecureStorage();
    await secureStorage.write(
      key: BackgroundSync.notificationsUnchecked,
      value: jsonEncode(uncheckedMessages),
    );
  } catch (error) {
    print('[saveNotificationsUnchecked] ${error.toString()}');
  }
}

///
/// Load Notification Data Unchecked (BackgroundSync)
///
/// Used to load settings while the background
/// sync thread is currently running
///
Future<Map<String, String>> loadNotificationsUnchecked() async {
  try {
    final secureStorage = FlutterSecureStorage();

    final uncheckedData = await secureStorage.read(
          key: BackgroundSync.notificationsUnchecked,
        ) ??
        '{}';
    final uncheckedJson = jsonDecode(uncheckedData);

    return Map<String, String>.from(uncheckedJson ?? {});
  } catch (error) {
    print('[loadNotificationsUnchecked] ${error.toString()}');
  }

  return <String, String>{};
}
