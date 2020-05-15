import 'dart:io';

import 'package:Tether/global/themes.dart';
import 'package:Tether/store/auth/state.dart';
import 'package:Tether/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/store/rooms/state.dart';
import 'package:Tether/store/settings/chat-settings/model.dart';
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:Tether/store/user/model.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:Tether/store/media/state.dart';
import 'package:Tether/store/settings/state.dart';

// Global cache
class Cache {
  static Box hive;
  static const defaultKey = 'tether@publicKey';

  static const globalBox = 'tether';
  static const matrixStateBox = 'full_matrix_state';
  static const backgroundServiceBox = 'tether_background_service';
}

/**
 * initHiveStorage - default
 * 
 * Initializes encrypted storage for caching  
 */
Future<dynamic> initHiveStorage() async {
  var storageLocation;
  var storageEngine;
  var storageEncryptionKeyRaw;
  var storageEncryptionKey = Hive.generateSecureKey();

  // Init storage location

  if (Platform.isIOS || Platform.isAndroid) {
    try {
      storageLocation = await getApplicationDocumentsDirectory();
    } catch (error) {
      print('[initHiveStorage] storage location failure - $error');
    }
  }

  if (Platform.isMacOS) {
    final storageLocation = await File('cache').create().then(
          (value) => value.writeAsString(
            '{}',
            flush: true,
          ),
        );
  }

  // Init hive cache
  Hive.init(storageLocation.path);

  // Init Custom Models
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ChatSettingAdapter());
  Hive.registerAdapter(RoomAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(ReadStatusAdapter());
  Hive.registerAdapter(UserAdapter());

  // Init Custom Store Models
  Hive.registerAdapter(AuthStoreAdapter());
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
  Hive.registerAdapter(RoomStoreAdapter());

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

/**
 * initHiveStorage UNSAFE
 * 
 * For testing purposes only
 */
Future<Box> initHiveBackgroundServiceUnsafe() async {
  var storageLocation;

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[initHiveBackgroundServiceUnsafe] Storage Location Failure $error');
  }

  // Init hive cache + adapters
  Hive.init(storageLocation.path);
  return await Hive.openBox(Cache.backgroundServiceBox);
}

/**
 * initHiveStorage UNSAFE
 * 
 * For testing purposes only
 */
Future<dynamic> initHiveStorageUnsafe() async {
  var storageLocation;

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[initHiveStorageUnsafe] Storage Location Failure- $error');
  }

  // Init hive cache + adapters
  Hive.init(storageLocation.path);

  // Custom Models
  Hive.registerAdapter(ThemeTypeAdapter());
  Hive.registerAdapter(ChatSettingAdapter());
  Hive.registerAdapter(RoomAdapter());
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(EventAdapter());
  Hive.registerAdapter(ReadStatusAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(DeviceAdapter());

  // Custom Store Models
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
  Hive.registerAdapter(RoomStoreAdapter());
  Hive.registerAdapter(AuthStoreAdapter());

  return await Hive.openBox(Cache.globalBox);
}
