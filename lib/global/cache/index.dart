import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class CacheSecure {
  // encryption references (in memory only)
  static String ivKey;
  static String ivKeyNext;
  static String cryptKey;

  // cache refrences
  static Box cacheMain;
  static Box cacheRooms;
  static Box cacheCrypto;

  // cache database references
  static Database cacheMainSql;

  // inital store caches for reload
  static Map<String, Map> cacheStoreDecoded = {};

  // cache storage identifiers
  static const cacheKeyMain = '${Values.appNameLabel}-main-cache';
  static const cacheKeyMainAlt = '${Values.appNameLabel}-main-cache-alt';
  static const cacheKeyRooms = '${Values.appNameLabel}-room-cache';
  static const cacheKeyCrypto = '${Values.appNameLabel}-crypto-cache';

  // cache key identifiers
  static const ivKeyLocation = '${Values.appNameLabel}@ivKey';
  static const ivKeyNextLocation = '${Values.appNameLabel}@ivKeyNext';
  static const cryptKeyLocation = '${Values.appNameLabel}@cryptKey';

  // background data identifiers
  static const roomNamesKey = 'roomNamesKey';
  static const protocolKey = 'protocol';
  static const homeserverKey = 'homeserver';
  static const accessTokenKey = 'accessToken';
  static const lastSinceKey = 'lastSince';
  static const userIdKey = 'userId';
}

Future<void> initCache() async {
  try {
    var factory;
    var databasePath = '${CacheSecure.cacheKeyMainAlt}.db';

    if (Platform.isAndroid || Platform.isIOS) {
      var directory = await getApplicationDocumentsDirectory();
      await directory.create(recursive: true);
      databasePath = join(directory.path, '${CacheSecure.cacheKeyMain}.db');
      factory = databaseFactoryIo;
      // factory = getDatabaseFactorySqflite(sqflite.databaseFactory);
    }

    /// Supports Windows/Linux/MacOS for now.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      factory = getDatabaseFactorySqflite(sqflite_ffi.databaseFactoryFfi);
    }

    if (factory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    // open sqlflite
    CacheSecure.cacheMainSql = await factory.openDatabase(
      databasePath,
    );
  } catch (error) {
    debugPrint('[initCache] ${error}');
  }

  // Configure cache encryption/decryption instance
  CacheSecure.ivKey = await unlockIVKey();
  CacheSecure.ivKeyNext = await unlockIVKeyNext();
  CacheSecure.cryptKey = await unlockCryptKey();
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

  if (CacheSecure.cacheMainSql != null) {
    CacheSecure.cacheMainSql.close();
  }
}

String createIVKey() {
  return CryptKey().genDart();
}

Future<void> saveIVKey(String ivKey) async {
  // Check if storage has been created before
  return await FlutterSecureStorage().write(
    key: CacheSecure.ivKeyLocation,
    value: ivKey,
  );
}

Future<void> saveIVKeyNext(String ivKey) async {
  // Check if storage has been created before
  return await FlutterSecureStorage().write(
    key: CacheSecure.ivKeyNextLocation,
    value: ivKey,
  );
}

Future<String> unlockIVKey() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  final ivKeyStored = await storageEngine.read(
    key: CacheSecure.ivKeyLocation,
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
