import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/settings/state.dart';

/**
 * Save Settings (Cold Storage)
 * 
 * Save the Settings store to cold storage
 * Idealy, run this after performance a pure action
 */
Future<void> saveSettings(
  SettingsStore settingsStore, {
  required Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.SETTINGS);

  return await storage.transaction((txn) async {
    final record = store.record(StorageKeys.SETTINGS);
    await record.put(txn, json.encode(settingsStore));
  });
}

/**
 * Load Settings (Cold Storage)
 * 
 * In storage, the Settings store is saved in it's entirety 
 * in a separate thread/isolate 
 */
Future<SettingsStore?> loadSettings({required Database storage}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.SETTINGS);

    final settings = await store.record(StorageKeys.SETTINGS).get(storage);

    if (settings == null) {
      return null;
    }

    return SettingsStore.fromJson(json.decode(settings));
  } catch (error) {
    printError(error.toString(), title: 'loadSettings');
    return null;
  }
}
