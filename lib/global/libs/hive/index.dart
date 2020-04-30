import 'package:Tether/global/themes.dart';
import 'package:Tether/store/settings/chat-settings/model.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:Tether/store/media/state.dart';
import 'package:Tether/store/settings/state.dart';

// Global cache
class Cache {
  static Box hive;
  static const globalBox = 'tether';
  static const defaultKey = 'tether@publicKey';
}

Future<dynamic> initHiveStorageUnsafe() async {
  var storageLocation;

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[initHiveStorage] storage location failure - $error');
  }

  // Init hive cache + adapters
  Hive.init(storageLocation.path);
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ChatSettingAdapter());

  return await Hive.openBox(Cache.globalBox);
}

/**
 * Initializes encrypted storage for caching 
 * Testing:
    print(box);
    print(box.keys);
    print(box.get('someone')); 
 */
Future<dynamic> initHiveStorage() async {
  var storageLocation;
  var storageEngine;
  var storageEncryptionKeyRaw;
  var storageEncryptionKey = Hive.generateSecureKey();

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[initHiveStorage] storage location failure - $error');
  }

  // Init hive cache
  Hive.init(storageLocation.path);

  // Init storage engine for hive key
  try {
    storageEngine = FlutterSecureStorage();

    // Check if storage has been created before
    storageEncryptionKeyRaw = await storageEngine.read(
      key: Cache.defaultKey,
    );

    // Create a encryptionKey if a serialized one is not found
    if (storageEncryptionKeyRaw == null) {
      storageEncryptionKey = Hive.generateSecureKey();

      await storageEngine.write(
        key: Cache.defaultKey,
        value: jsonEncode(storageEncryptionKey),
      );

      storageEncryptionKeyRaw = await storageEngine.read(
        key: Cache.defaultKey,
      );
    }

    // Decode raw encryption key
    storageEncryptionKey = jsonDecode(storageEncryptionKeyRaw).cast<int>();
  } catch (error) {
    print('[initHiveStorage] storage engine failure - $error');
  }

  return await Hive.openBox(Cache.globalBox,
      encryptionKey: storageEncryptionKey);
}

// AppState rehydateStore() {
//   Box<dynamic> box = Hive.box(HIVE_BOX_NAME);
//   AppState state = box.get(APPSTATE_HIVE_KEY);
//   return state;
// }

// void cacheStore(AppState state) async {
//   Box<dynamic> box = Hive.box(HIVE_BOX_NAME);
//   box.put(APPSTATE_HIVE_KEY, state);
// }

// void clearStorage() {
//   Box<dynamic> box = Hive.box(HIVE_BOX_NAME);
//   box.put(APPSTATE_HIVE_KEY, null);
// }

// // Closes and saves storage
void closeStorage() async {
  Box<dynamic> box = Hive.box(Cache.globalBox);
  box.close();
}
