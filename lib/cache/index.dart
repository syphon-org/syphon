import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/secure-keys.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class Cache {
  // cache key identifiers
  static const keyLocation = '${Values.appNameLabel}@cryptKey';

  // cache storage identifiers
  static const defaultLocation = '${Values.appNameLabel}-main-cache.db';

  // background data identifiers
  static const userIdKey = 'userId';
  static const protocolKey = 'protocol';
  static const lastSinceKey = 'lastSince';
  static const homeserverKey = 'homeserver';
  static const roomNamesKey = 'roomNamesKey';
  static const accessTokenKey = 'accessToken';

  // encryption references (in memory only)
  static String? cryptKey;

  // hot cache refrences
  static Database? cacheMain;

  // inital store caches for reload
  static Map<String, Map?> cacheStores = {};
}

///
/// Init Hot Cache
///
Future<Database?> initCache() async {
  try {
    var cachePath = Cache.defaultLocation;
    var cacheFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationSupportDirectory();
      await directory.create();
      cachePath = join(directory.path, Cache.defaultLocation);
      cacheFactory = databaseFactoryIo;
    }

    // Configure cache encryption/decryption instance
    Cache.cryptKey = await loadKey(Cache.keyLocation);

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
    var cachePath = Cache.defaultLocation;

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
