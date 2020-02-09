import 'dart:io';
import 'dart:typed_data';

import 'package:Tether/domain/index.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:redux_persist/redux_persist.dart';

const STORAGE_ENCRYPTION_KEY = 'tether@hivekey';
const HIVE_BOX_NAME = 'tether';
const APPSTATE_HIVE_KEY = 'app_state';

// Global cache
class Cache {
  static Box hive;
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
  var storageEncryptionKey = List<int>(
    0xAFBC9393, // TODO: ONLY FOR TESTING
  );

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
      key: STORAGE_ENCRYPTION_KEY,
    );

    // Create a encryptionKey if a serialized one is not found
    if (storageEncryptionKeyRaw == null) {
      storageEncryptionKey = Hive.generateSecureKey();

      await storageEngine.write(
        key: STORAGE_ENCRYPTION_KEY,
        value: jsonEncode(storageEncryptionKey),
      );

      storageEncryptionKeyRaw = await storageEngine.read(
        key: STORAGE_ENCRYPTION_KEY,
      );
    }

    // Decode raw encryption key
    storageEncryptionKey = jsonDecode(storageEncryptionKeyRaw).cast<int>();
  } catch (error) {
    print('[initHiveStorage] storage engine failure - $error');
  }

  return await Hive.openBox(HIVE_BOX_NAME, encryptionKey: storageEncryptionKey);
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
  Box<dynamic> box = Hive.box(HIVE_BOX_NAME);
  box.close();
  // print();
}
