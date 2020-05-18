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

  static const defaultCacheKey = 'tether_cache_unsafe';

  static const stateKey = 'tether_cache';
  static const syncKey = 'tether_cache_sync';
  static const backgroundKey = 'tether_cache_background';
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
  Hive.registerAdapter(MediaStoreAdapter());
  Hive.registerAdapter(SettingsStoreAdapter());
  Hive.registerAdapter(RoomStoreAdapter());
  Hive.registerAdapter(AuthStoreAdapter());
}

/**
 * initHiveStorage UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> initHiveStorageUnsafe() async {
  // Init storage location
  final storageLocation = await initColdStorageLocation();

  // Init configuration
  await initHiveConfiguration(storageLocation);

  return await Hive.openBox(Cache.defaultCacheKey);
}

/**
 * initHiveStorage UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<Box> initHiveBackgroundServiceUnsafe() async {
  // Init storage location
  final storageLocation = await initColdStorageLocation();

  // Init configuration
  await initHiveConfiguration(storageLocation);

  return await Hive.openBox(Cache.syncKey);
}

/**
 * initHiveStorage - default
 * 
 * Initializes encrypted storage for caching  
 */
Future<Box> initHiveStorage() async {
  // Init storage engine for hive key

  // Init storage location
  final storageLocation = await initColdStorageLocation();

  // Init configuration
  await initHiveConfiguration(storageLocation);

  var encryptionKey;
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();
  try {
    encryptionKey = await storageEngine.read(
      key: Cache.defaultKey,
    );

    // Create a encryptionKey if a serialized one is not found
    if (encryptionKey == null) {
      final generatedEncryptionkey = Hive.generateSecureKey();

      await storageEngine.write(
        key: Cache.defaultKey,
        value: jsonEncode(generatedEncryptionkey),
      );

      encryptionKey = await storageEngine.read(
        key: Cache.defaultKey,
      );
    }

    // Decode raw encryption key
    encryptionKey = List<int>.from(jsonDecode(encryptionKey));

    print('[initHiveStorage] $encryptionKey');
    return await Hive.openBox(
      Cache.stateKey,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
  } catch (error) {
    print('[initHiveStorage] storage engine failure - $error');
    return await Hive.openBox(
      Cache.defaultCacheKey,
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
