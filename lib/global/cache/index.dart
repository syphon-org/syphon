import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/values.dart';

class CacheSecure {
  // encryption references (in memory only)
  static String ivKey;
  static String ivKeyNext;
  static String cryptKey;

  // encryption references (custom)
  static String ivKeyUsers;
  static String ivKeyUsersNext;

  // cache refrences
  static Box cacheMain;
  static Box cacheRooms;
  static Box cacheCrypto;
  static Box cacheUsers;

  // cache storage identifiers
  static const cacheKeyMain = '${Values.appNameLabel}-main-cache';
  static const cacheKeyRooms = '${Values.appNameLabel}-room-cache';
  static const cacheKeyCrypto = '${Values.appNameLabel}-crypto-cache';
  static const cacheKeyUsers = '${Values.appNameLabel}-crypto-users';

  // cache key identifiers
  static const ivKeyLocation = '${Values.appNameLabel}@ivKey';
  static const ivKeyNextLocation = '${Values.appNameLabel}@ivKeyNext';
  static const cryptKeyLocation = '${Values.appNameLabel}@cryptKey';

  // caceh key identifiers (custom)
  static const ivKeyUsersLocation = '${Values.appNameLabel}@ivKeyUsers';
  static const ivKeyUsersNextLocation = '${Values.appNameLabel}@ivKeyUsersNext';

  // background data identifiers
  static const roomNamesKey = 'roomNamesKey';
  static const protocolKey = 'protocol';
  static const homeserverKey = 'homeserver';
  static const accessTokenKey = 'accessToken';
  static const lastSinceKey = 'lastSince';
  static const userIdKey = 'userId';
}

Future<void> initCache() async {
  // Init storage location
  final String storageLocation = await initStorageLocation();

  // Init configuration
  Hive.init(storageLocation);

  CacheSecure.cacheMain = await unlockMainCache();
  CacheSecure.cacheRooms = await unlockRoomCache();
  CacheSecure.cacheCrypto = await unlockCryptoCache();
  CacheSecure.cacheUsers = await unlockUsersCache();
}

Future<dynamic> initStorageLocation() async {
  var storageLocation;

  try {
    if (Platform.isIOS || Platform.isAndroid) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    if (Platform.isMacOS) {
      storageLocation = await File('cache').create().then(
            (value) => value.writeAsString(
              '{}',
              flush: true,
            ),
          );

      return storageLocation.path;
    }

    if (Platform.isLinux) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    debugPrint('[initStorageLocation] no cache support');
    return null;
  } catch (error) {
    debugPrint('[initStorageLocation] $error');
    return null;
  }
}

// // Closes and saves storage
void closeCache() async {
  if (CacheSecure.cacheMain != null && CacheSecure.cacheMain.isOpen) {
    CacheSecure.cacheMain.close();
  }

  if (CacheSecure.cacheRooms != null && CacheSecure.cacheRooms.isOpen) {
    CacheSecure.cacheRooms.close();
  }

  if (CacheSecure.cacheCrypto != null && CacheSecure.cacheCrypto.isOpen) {
    CacheSecure.cacheCrypto.close();
  }

  if (CacheSecure.cacheUsers != null && CacheSecure.cacheUsers.isOpen) {
    CacheSecure.cacheUsers.close();
  }
}

String createIVKey() {
  return CryptKey().genDart();
}

Future<void> saveIVKey(
  String ivKey, {
  String ivKeyLocation = CacheSecure.ivKeyLocation,
}) async {
  return await FlutterSecureStorage().write(
    key: ivKeyLocation,
    value: ivKey,
  );
}

Future<String> unlockIVKey({location = CacheSecure.ivKeyLocation}) async {
  final storageEngine = FlutterSecureStorage();

  final ivKeyStored = await storageEngine.read(
    key: location,
  );

  // Create a encryptionKey if a serialized one is not found
  return ivKeyStored == null ? createIVKey() : ivKeyStored;
}

Future<String> unlockIVKeyNext() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  final ivKeyStored = await storageEngine.read(
    key: CacheSecure.ivKeyNextLocation,
  );

  // Create a encryptionKey if a serialized one is not found
  return ivKeyStored == null ? createIVKey() : ivKeyStored;
}

Future<String> unlockCryptKey() async {
  final storageEngine = FlutterSecureStorage();

  var cryptKey;

  try {
    // Check if crypt key already exists
    cryptKey = await storageEngine.read(
      key: CacheSecure.cryptKeyLocation,
    );
  } catch (error) {
    debugPrint('[unlockCryptKey] ${error}');
  }

  // Create a encryptionKey if a serialized one is not found
  if (cryptKey == null) {
    cryptKey = CryptKey().genFortuna(len: 32); // 256 bits

    await storageEngine.write(
      key: CacheSecure.cryptKeyLocation,
      value: cryptKey,
    );
  }

  return cryptKey;
}

Future<Box> unlockMainCache() async {
  try {
    return await Hive.openBox(
      CacheSecure.cacheKeyMain,
      crashRecovery: true,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[unlockMainCache] $error');
    return null;
  }
}

Future<Box> unlockRoomCache() async {
  try {
    return await Hive.openBox(
      CacheSecure.cacheKeyRooms,
      crashRecovery: true,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[unlockRoomCache] $error');
    return null;
  }
}

Future<Box> unlockCryptoCache() async {
  try {
    return await Hive.openBox(
      CacheSecure.cacheKeyCrypto,
      crashRecovery: true,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[unlockCryptoCache] $error');
    return null;
  }
}

Future<Box> unlockUsersCache() async {
  try {
    return await Hive.openBox(
      CacheSecure.cacheKeyCrypto,
      crashRecovery: true,
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
    );
  } catch (error) {
    debugPrint('[unlockCryptoCache] $error');
    return null;
  }
}
