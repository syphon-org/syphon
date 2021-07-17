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
  static String? cryptKey;

  // hot cache refrences
  static Database? cacheMain;

// Global hot cache storage reference to prevent redundent storage loading
  static FlutterSecureStorage? keyStorage;

  // inital store caches for reload
  static Map<String, Map?> cacheStores = {};

  // cache storage identifiers
  static const cacheKeyMain = '${Values.appNameLabel}-main-cache';
  static const cachePath = '${Cache.cacheKeyMain}.db';

  // cache key identifiers
  static const keyLocation = '${Values.appNameLabel}@cryptKey';

  // background data identifiers
  static const userIdKey = 'userId';
  static const protocolKey = 'protocol';
  static const lastSinceKey = 'lastSince';
  static const homeserverKey = 'homeserver';
  static const roomNamesKey = 'roomNamesKey';
  static const accessTokenKey = 'accessToken';
}

///
/// Init Hot Cache
///
Future<Database?> initCache() async {
  try {
    var cachePath = Cache.cachePath;
    var cacheFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      Cache.keyStorage = FlutterSecureStorage();

      final directory = await getApplicationSupportDirectory();
      await directory.create();
      cachePath = join(directory.path, Cache.cachePath);
      cacheFactory = databaseFactoryIo;
    }

    // Configure cache encryption/decryption instance
    Cache.cryptKey = await loadCacheKey();

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
    printError('[initCache] $error');
    return null;
  }
}

// Closes and saves storage
closeCache(Database? cache) async {
  if (cache != null) {
    cache.close();
  }
}

deleteCache({Database? cache}) async {
  try {
    late var cacheFactory;
    var cachePath = Cache.cachePath;

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationSupportDirectory();
      await directory.create();
      cachePath = join(directory.path, cachePath);
      cacheFactory = databaseFactoryIo;
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      cacheFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    Cache.cacheMain = await cacheFactory.deleteDatabase(cachePath);
  } catch (error) {
    printError('[initCache] $error');
  }
}

String generateKey() {
  return Key.fromSecureRandom(32).base64;
}

Future<String?> loadCacheId() async {}

Future<String?> loadCacheKey() async {
  const location = Cache.keyLocation;

  var key;

  // mobile
  if (Platform.isAndroid || Platform.isIOS) {
    final keyStorage = Cache.keyStorage!;

    // try to read key
    try {
      key = await keyStorage.read(key: location);
    } catch (error) {
      printError('[loadKey] $error');
    }

    // generate a new one on failure
    if (key == null) {
      key = generateKey();
      await keyStorage.write(key: Cache.keyLocation, value: key);
    }
  }

  // desktop
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    // try to read key
    try {
      final directory = await getApplicationSupportDirectory();
      key = await File(join(directory.path, location)).readAsString();
    } catch (error) {
      printError('[loadKey] $error');
    }

    // generate a new one on failure
    try {
      if (key == null) {
        final directory = await getApplicationSupportDirectory();
        key = generateKey();
        await File(join(directory.path, location)).writeAsString(key, flush: true);
      }
    } catch (error) {
      printError('[loadKey] $error');
    }
  }

  return key;
}
