import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class CacheSecure {
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
Future<void> initCache() async {
  // Configure cache encryption/decryption instance
  CacheSecure.ivKey = await unlockIVKey();
  CacheSecure.ivKeyNext = await unlockIVKeyNext();
  CacheSecure.cryptKey = await unlockCryptKey();
  try {
    var cacheFactory;

    var cachePath = '${CacheSecure.cacheKeyMain}.db';

    if (Platform.isAndroid || Platform.isIOS) {
      var directory = await getApplicationDocumentsDirectory();
      await directory.create();
      cachePath = join(directory.path, '${CacheSecure.cacheKeyMain}.db');
      cacheFactory = databaseFactoryIo;
    }

    /// Supports Windows/Linux/MacOS for now.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      // open cache w/ sqflite ffi for desktop compat
      cacheFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    if (factory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    CacheSecure.cacheMain = await cacheFactory.openDatabase(
      cachePath,
    );
    return Future.sync(() => null);
  } catch (error) {
    debugPrint('[initCache] ${error}');
  }
}

// // Closes and saves storage
void closeCache() async {
  if (CacheSecure.cacheMain != null) {
    CacheSecure.cacheMain.close();
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
