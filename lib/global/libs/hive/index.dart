import 'dart:io';
import 'dart:typed_data';

import 'package:Tether/global/themes.dart';
import 'package:Tether/store/auth/state.dart';
import 'package:Tether/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/store/rooms/state.dart';
import 'package:Tether/store/settings/chat-settings/model.dart';
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:Tether/store/sync/state.dart';
import 'package:Tether/store/user/model.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

import 'package:Tether/store/media/state.dart';
import 'package:Tether/store/settings/state.dart';

// Global cache
class Cache {
  static Box state;
  static LazyBox sync;

  static const encryptionKeyLocation = 'tether@publicKey';

  static const syncKey = 'tether_sync';
  static const stateKey = 'tether_cache';

  static const syncKeyUNSAFE = 'tether_sync_unsafe';
  static const stateKeyUNSAFE = 'tether_cache_unsafe';
  static const backgroundKeyUNSAFE = 'tether_background_cache_unsafe';

  static const backgroundAccessToken = 'accessToken';
  static const backgroundLastSince = 'lastSince';
}

Future<dynamic> initColdStorageLocation() async {
  var storageLocation;

  try {
    if (Platform.isIOS || Platform.isAndroid) {
      storageLocation = await getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS) {
      storageLocation = await File('cache').create().then(
            (value) => value.writeAsString(
              '{}',
              flush: true,
            ),
          );
    } else {
      print('Caching is not supported on this platform');
    }
  } catch (error) {
    print('[initColdStorageLocation] storage location failure - $error');
  }
  return storageLocation;
}

Future<void> initHiveConfiguration(dynamic storageLocation) async {
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
  Hive.registerAdapter(DeviceAdapter());

  // Custom Store Models
  Hive.registerAdapter(AuthStoreAdapter());
  Hive.registerAdapter(SyncStoreAdapter());
  Hive.registerAdapter(RoomStoreAdapter());
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<void> initHive() async {
  // Init storage location
  final storageLocation = await initColdStorageLocation();

  // Init configuration
  await initHiveConfiguration(storageLocation);
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> openHiveStateUnsafe() async {
  return await Hive.openBox(
    Cache.stateKeyUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<LazyBox> openHiveSyncUnsafe() async {
  return await Hive.openLazyBox(
    Cache.syncKeyUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> openHiveBackgroundUnsafe() async {
  return await Hive.openBox(
    Cache.backgroundKeyUNSAFE,
    compactionStrategy: (entries, deletedEntries) => deletedEntries > 2,
  );
}

/**
 * Open Hive State
 * 
 * Initializes encrypted storage for caching current state
 */
Future<Box> openHiveState() async {
  var encryptionKey;
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();
  try {
    encryptionKey = await storageEngine.read(
      key: Cache.encryptionKeyLocation,
    );

    // Create a encryptionKey if a serialized one is not found
    if (encryptionKey == null) {
      final generatedEncryptionkey = Hive.generateSecureKey();

      await storageEngine.write(
        key: Cache.encryptionKeyLocation,
        value: jsonEncode(generatedEncryptionkey),
      );

      encryptionKey = await storageEngine.read(
        key: Cache.encryptionKeyLocation,
      );
    }

    // Decode raw encryption key
    encryptionKey = List<int>.from(jsonDecode(encryptionKey));

    print('[openHiveState] $encryptionKey');
    return await Hive.openBox(
      Cache.stateKey,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    print('[openHiveState] storage engine failure - $error');
    return await Hive.openBox(
      Cache.stateKeyUNSAFE,
    );
  }
}

/**
 *  Open Hive Sync
 * 
 * Initializes encrypted storage for caching sync
 */
Future<LazyBox> openHiveSync() async {
  var encryptionKey;
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();
  try {
    encryptionKey = await storageEngine.read(
      key: Cache.encryptionKeyLocation,
    );

    // Create a encryptionKey if a serialized one is not found
    if (encryptionKey == null) {
      final generatedEncryptionkey = Hive.generateSecureKey();

      await storageEngine.write(
        key: Cache.encryptionKeyLocation,
        value: jsonEncode(generatedEncryptionkey),
      );

      encryptionKey = await storageEngine.read(
        key: Cache.encryptionKeyLocation,
      );
    }

    // Decode raw encryption key
    encryptionKey = List<int>.from(jsonDecode(encryptionKey));

    return await Hive.openLazyBox(
      Cache.syncKey,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    print('[openHiveState] failure $error');
    return await Hive.openLazyBox(
      Cache.syncKeyUNSAFE,
    );
  }
}

// // Closes and saves storage
void closeStorage() async {
  Box<dynamic> box = Hive.box(Cache.stateKey);
  box.close();
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
