import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class Cache {
  // encryption references (in memory only)
  static String ivKey;
  static String ivKeyNext;
  static String cryptKey;

  // hot cachee refrences
  static Database cacheMain;

  // inital store caches for reload
  static Map<String, Map> cacheStores = {};

  // cache storage identifiers
  static const cacheKeyMain = '${Values.appNameLabel}-main-cache';

  // cache key identifiers
  static const ivKeyLocation = '${Values.appNameLabel}@ivKey';
  static const ivKeyNextLocation = '${Values.appNameLabel}@ivKeyNext';
  static const cryptKeyLocation = '${Values.appNameLabel}@cryptKey';

  // background data identifiers
  static const userIdKey = 'userId';
  static const protocolKey = 'protocol';
  static const lastSinceKey = 'lastSince';
  static const homeserverKey = 'homeserver';
  static const roomNamesKey = 'roomNamesKey';
  static const accessTokenKey = 'accessToken';
}

/**
 * Init Cache
 * 
 * (needs cold storage extracted as it's own entity)
 */
Future<Database> initCache() async {
  // Configure cache encryption/decryption instance
  Cache.ivKey = await unlockIVKey();
  Cache.ivKeyNext = await unlockIVKeyNext();
  Cache.cryptKey = await unlockCryptKey();

  try {
    var cachePath = '${Cache.cacheKeyMain}.db';
    var cacheFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      var directory = await getApplicationDocumentsDirectory();
      await directory.create();
      cachePath = join(directory.path, '${Cache.cacheKeyMain}.db');
      cacheFactory = databaseFactoryIo;
    }

    /// Supports Windows/Linux/MacOS for now.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // open cache w/ sqflite ffi for desktop compat
      cacheFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    if (cacheFactory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    Cache.cacheMain = await cacheFactory.openDatabase(
      cachePath,
    );

    return Cache.cacheMain;
  } catch (error) {
    printDebug('[initCache] ${error}');
    return null;
  }
}

// // Closes and saves storage
void closeCache(Database cache) async {
  if (cache != null) {
    cache.close();
  }
}

String createIVKey() {
  return Key.fromSecureRandom(16).base64;
}

Future<void> saveIVKey(String ivKey) async {
  // Check if storage has been created before
  return await FlutterSecureStorage().write(
    key: Cache.ivKeyLocation,
    value: ivKey,
  );
}

Future<void> saveIVKeyNext(String ivKey) async {
  // Check if storage has been created before
  return await FlutterSecureStorage().write(
    key: Cache.ivKeyNextLocation,
    value: ivKey,
  );
}

Future<String> unlockIVKey() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  final ivKeyStored = await storageEngine.read(
    key: Cache.ivKeyLocation,
  );

  // Create a encryptionKey if a serialized one is not found
  return ivKeyStored == null ? createIVKey() : ivKeyStored;
}

Future<String> unlockIVKeyNext() async {
  // Check if storage has been created before
  final storageEngine = FlutterSecureStorage();

  final ivKeyStored = await storageEngine.read(
    key: Cache.ivKeyNextLocation,
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
      key: Cache.cryptKeyLocation,
    );
  } catch (error) {
    printDebug('[unlockCryptKey] ${error}');
  }

  // Create a encryptionKey if a serialized one is not found
  if (cryptKey == null) {
    cryptKey = Key.fromSecureRandom(32).base64;

    await storageEngine.write(
      key: Cache.cryptKeyLocation,
      value: cryptKey,
    );
  }

  return cryptKey;
}
