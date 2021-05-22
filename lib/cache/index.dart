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
  static String? ivKey;
  static String? ivKeyNext;
  static String? cryptKey;

  // hot cache refrences
  static Database? cacheMain;

// Global hot cache storage reference to prevent redundent storage loading
  static FlutterSecureStorage? storage;

  // inital store caches for reload
  static Map<String, Map?> cacheStores = {};

  // cache storage identifiers
  static const cacheKeyMain = '${Values.appNameLabel}-main-cache';

  // cache key identifiers
  static const ivLocation = '${Values.appNameLabel}@ivKey';
  static const ivLocationNext = '${Values.appNameLabel}@ivKeyNext';
  static const keyLocation = '${Values.appNameLabel}@cryptKey';

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
Future<Database?> initCache() async {
  try {
    var cachePath = '${Cache.cacheKeyMain}.db';
    var cacheFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      Cache.storage = FlutterSecureStorage();

      var directory = await getApplicationSupportDirectory();
      await directory.create();
      cachePath = join(directory.path, '${Cache.cacheKeyMain}.db');
      cacheFactory = databaseFactoryIo;
    }

    // Configure cache encryption/decryption instance
    Cache.ivKey = await loadIV();
    Cache.ivKeyNext = await loadIVNext();
    Cache.cryptKey = await loadKey();

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
    printError('[initCache] ${error}');
    return null;
  }
}

// // Closes and saves storage
void closeCache(Database? cache) async {
  if (cache != null) {
    cache.close();
  }
}

Future<void> deleteCache({Database? cache}) async {
  try {
    late var cacheFactory;
    var cachePath = '${Cache.cacheKeyMain}.db';

    if (Platform.isAndroid || Platform.isIOS) {
      var directory = await getApplicationSupportDirectory();
      await directory.create();
      cachePath = join(directory.path, '${Cache.cacheKeyMain}.db');
      cacheFactory = databaseFactoryIo;
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      cacheFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    Cache.cacheMain = await cacheFactory.deleteDatabase(cachePath);
  } catch (error) {
    printError('[initCache] ${error}');
    return null;
  }
}

String generateIV() {
  return Key.fromSecureRandom(16).base64;
}

String generateKey() {
  return Key.fromSecureRandom(32).base64;
}

Future<void> saveIV(String? iv) async {
  // mobile
  if (Platform.isAndroid || Platform.isIOS) {
    final storage = Cache.storage!;

    return await storage.write(key: Cache.ivLocation, value: iv);
  }

  // desktop
  try {
    final directory = await getApplicationSupportDirectory();
    await File(join(directory.path, Cache.ivLocation)).create()
      ..writeAsString(iv!, flush: true);
  } catch (error) {
    printError('[saveIV] $error');
  }

  // error
  return null;
}

Future<String> loadIV() async {
  final location = Cache.ivLocation;
  var ivStored;

  if (Platform.isAndroid || Platform.isIOS) {
    final storage = Cache.storage!;
    ivStored = await storage.read(key: location);
  }

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    try {
      final directory = await getApplicationSupportDirectory();
      ivStored = await File(join(directory.path, location)).readAsString();
    } catch (error) {
      printError('[loadIV] $error');
    }
  }
  // Create a encryptionKey if a serialized one is not found
  return ivStored == null ? generateIV() : ivStored;
}

Future<void> saveIVNext(String? iv) async {
  // mobile
  if (Platform.isAndroid || Platform.isIOS) {
    final storage = Cache.storage!;
    return await storage.write(
      key: Cache.ivLocationNext,
      value: iv,
    );
  }

  // desktop
  try {
    final directory = await getApplicationSupportDirectory();
    await File(join(directory.path, Cache.ivLocationNext)).create()
      ..writeAsString(iv!, flush: true);
  } catch (error) {
    printError('[saveIVNext] $error');
  }

  // desktop
  return null;
}

Future<String> loadIVNext() async {
  final location = Cache.ivLocationNext;

  var ivStored;

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      final storage = Cache.storage!;
      ivStored = await storage.read(key: location);
    } catch (error) {
      printError('[loadIVNext] $error');
    }
  }

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    try {
      final directory = await getApplicationSupportDirectory();
      ivStored = await File(join(directory.path, location)).readAsString();
    } catch (error) {
      printError('[loadIVNext] $error');
    }
  }

  // Create a encryptionKey if a serialized one is not found
  return ivStored == null ? generateIV() : ivStored;
}

Future<String?> loadKey() async {
  final location = Cache.keyLocation;
  var key;

  // mobile
  if (Platform.isAndroid || Platform.isIOS) {
    final storage = Cache.storage!;

    // try to read key
    try {
      key = await storage.read(key: location);
    } catch (error) {
      printError('[loadKey] ${error}');
    }

    // generate a new one on failure
    if (key == null) {
      key = generateKey();
      await storage.write(key: Cache.keyLocation, value: key);
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
        await File(join(directory.path, location))
            .writeAsString(key, flush: true);
      }
    } catch (error) {
      printError('[loadKey] $error');
    }
  }

  return key;
}
