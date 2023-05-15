import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/sync/service/service.dart';

FlutterSecureStorage? _secureStorage;

_initStorage() {
  if (_secureStorage != null) return;
  _secureStorage = FlutterSecureStorage();
}

///
/// Save Room Names (SyncService)
///
/// Save the crypto store to cold storage
/// Idealy, run this after performance a pure action
Future saveRoomNames({required Map<String, String> roomNames}) async {
  // Try to pull new lastSince if available
  try {
    if (roomNames.isEmpty) return;

    _initStorage();

    await _secureStorage!.write(
      key: SyncService.roomNamesKey,
      value: jsonEncode(roomNames),
    );
  } catch (error) {
    log.error('[saveRoomNames] $error');
  }
}

///
/// Load Room Names (SyncService)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<Map<String, String>> loadRoomNames() async {
  try {
    _initStorage();
    return Map<String, String>.from(
      await jsonDecode(
        await _secureStorage!.read(key: SyncService.roomNamesKey) ?? '{}',
      ),
    );
  } catch (error) {
    try {
      _initStorage();
      _secureStorage!.delete(key: SyncService.roomNamesKey);
    } catch (error) {}
    log.error('[loadRoomNames] $error');
  }

  return <String, String>{};
}

///
/// Load Last Since (SyncService)
///
/// Save the crypto store to cold storage
/// Idealy, run this after performance a pure action
Future saveLastSince({required String lastSince}) async {
  // Try to pull new lastSince if available
  try {
    if (lastSince.isEmpty) return;

    _initStorage();
    await _secureStorage!.write(key: SyncService.lastSinceKey, value: lastSince);
  } catch (error) {
    log.error('[saveLastSince] $error');
  }
}

///
/// Load Crypto (SyncService)
///
/// In storage, the crypto store is saved in it's entirety
/// in a separate thread/isolate
Future<String> loadLastSince({required String fallback}) async {
  try {
    _initStorage();
    return await _secureStorage!.read(key: SyncService.lastSinceKey) ?? fallback;
  } catch (error) {
    log.error('[loadLastSince] $error');
  }

  return fallback;
}

///
/// Save Notification Settings (SyncService)
///
/// Used to update settings while the background
/// sync thread is currently running
///
Future saveNotificationSettings({NotificationSettings? settings}) async {
  // Try to pull new lastSince if available
  try {
    if (settings == null) return;

    _initStorage();
    await _secureStorage!.write(
      key: SyncService.notificationSettingsKey,
      value: jsonEncode(settings),
    );
  } catch (error) {
    log.error('[saveNotificationSettings] $error');
  }
}

///
/// Load Notification Settings (SyncService)
///
/// Used to load settings while the background
/// sync thread is currently running
///
Future<NotificationSettings> loadNotificationSettings(
    {NotificationSettings fallback = const NotificationSettings()}) async {
  try {
    _initStorage();
    final settingsEncoded = await _secureStorage!.read(
      key: SyncService.notificationSettingsKey,
    );

    final settingsJson = await jsonDecode(settingsEncoded!);

    return NotificationSettings.fromJson(settingsJson);
  } catch (error) {
    log.error('[loadNotificationSettings] $error');
  }

  return fallback;
}

///
/// Save Notification Data Unchecked (SyncService)
///
/// Used to save unchecked notification data when
/// the notification style is Inbox. Aggregates all unchecked
/// notifications into one.
///
Future saveNotificationsUnchecked(Map<String, String> uncheckedMessages) async {
  try {
    _initStorage();
    await _secureStorage!.write(
      key: SyncService.notificationsUncheckedKey,
      value: jsonEncode(uncheckedMessages),
    );
  } catch (error) {
    log.error('[saveNotificationsUnchecked] $error');
  }
}

///
/// Load Notification Data Unchecked (SyncService)
///
/// Used to load settings while the background
/// sync thread is currently running
///
Future<Map<String, String>> loadNotificationsUnchecked() async {
  try {
    _initStorage();
    final uncheckedData = await _secureStorage!.read(
          key: SyncService.notificationsUncheckedKey,
        ) ??
        '{}';
    final uncheckedJson = jsonDecode(uncheckedData);

    return Map<String, String>.from(uncheckedJson ?? {});
  } catch (error) {
    log.error('[loadNotificationsUnchecked] $error');
  }

  return <String, String>{};
}
