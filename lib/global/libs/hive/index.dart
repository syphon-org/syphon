import 'dart:io';
import 'package:Tether/store/keys/state.dart';
import 'package:convert/convert.dart';

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

import 'package:Tether/store/media/state.dart';
import 'package:Tether/store/settings/state.dart';

// Global cache
class Cache {
  static Box state;
  static LazyBox sync;

  static const group_id = 'tether';
  static const encryptionKeyLocation = 'tether@publicKey';

  static const syncKey = 'tether_sync';
  static const stateKey = 'tether_cache';

  static const syncKeyUNSAFE = 'tether_sync_unsafe';
  static const stateKeyUNSAFE = 'tether_cache_unsafe';
  static const backgroundKeyUNSAFE = 'tether_background_cache_unsafe';

  static const syncData = 'sync_data';
  static const protocol = 'protocol';
  static const homeserver = 'homeserver';
  static const accessTokenKey = 'accessToken';
  static const lastSinceKey = 'lastSince';
}

/**
 * openHiveState UNSAFE
 * 
 * For testing purposes only - should be encrypting hive
 */
Future<void> initHive() async {
  // Init storage location
  final storageLocation = await initStorageLocation();

  print('[initHive] $storageLocation');

  // Init configuration
  await initHiveConfiguration(storageLocation);
}

Future<dynamic> initStorageLocation() async {
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
    print('[initStorageLocation] storage location failure - $error');
  }
  return storageLocation.path;
}

Future<void> initHiveConfiguration(String storageLocationPath) async {
  print('[initHiveConfiguration] $storageLocationPath');
  // Init hive cache
  Hive.init(storageLocationPath);

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
  Hive.registerAdapter(KeyStoreAdapter());
}

Future<List<int>> unlockEncryptionKey() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  var encryptionKey = await storageEngine.read(
    key: Cache.encryptionKeyLocation,
  );
  print(
      '[unlockEncryptionKey] loaded ${encryptionKey.runtimeType} ${encryptionKey}');

  // Create a encryptionKey if a serialized one is not found
  if (encryptionKey == null) {
    encryptionKey = hex.encode(Hive.generateSecureKey());

    print('[unlockEncryptionKey] save ${encryptionKey.runtimeType}');
    await storageEngine.write(
      key: Cache.encryptionKeyLocation,
      value: encryptionKey,
    );
  }

  print('[unlockEncryptionKey] decode ${encryptionKey.runtimeType}');

  return hex.decode(encryptionKey);
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
  var storageLocation;

  // Init storage location
  try {
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[openHiveBackgroundUnsafe] Storage Failure $error');
  }

  // Init hive cache + adapters
  Hive.init(storageLocation.path);
  return await Hive.openBox(Cache.backgroundKeyUNSAFE);
}

/**
 * Open Hive State
 * 
 * Initializes encrypted storage for caching current state
 */
Future<Box> openHiveState() async {
  try {
    final encryptionKey = await unlockEncryptionKey();
    return await Hive.openBox(
      Cache.stateKey,
      crashRecovery: false,
      encryptionCipher: HiveAesCipher(encryptionKey),
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    print('[openHiveState] open failure: $error');
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
  try {
    final encryptionKey = await unlockEncryptionKey();

    return await Hive.openLazyBox(
      Cache.syncKey,
      crashRecovery: false,
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
  if (Cache.sync != null && Cache.sync.isOpen) {
    Cache.sync.close();
  }

  if (Cache.state != null && Cache.state.isOpen) {
    Cache.sync.close();
  }
}
