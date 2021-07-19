import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/key-storage.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

class Cache {
  // cache key identifiers
  static const keyLocation = '${Values.appLabel}@cryptKey';

  // cache storage identifiers
  static const databaseLocation = '${Values.appLabel}-main-cache.db';

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
  static Database? instance;

  // inital store caches for reload
  static Map<String, Map?> cacheStores = {};
}

///
/// Init Hot Cache
///
Future<Database?> initCache({String? context = StoreContext.DEFAULT}) async {
  try {
    var cacheKeyId = Cache.keyLocation;
    var cacheLocation = Cache.databaseLocation;

    if (context!.isNotEmpty) {
      cacheKeyId = '$context-${Cache.keyLocation}';
      cacheLocation = '$context-${Cache.databaseLocation}';
    }

    var cacheFactory;

    // Configure cache encryption/decryption instance
    final cryptKey = await loadKey(cacheKeyId);

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationSupportDirectory();
      await directory.create();
      cacheLocation = join(directory.path, cacheLocation);
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

    print('initCache');
    print(cacheLocation);
    print(cryptKey);

    Cache.cryptKey = cryptKey;
    Cache.instance = await cacheFactory.openDatabase(
      cacheLocation,
    );

    return Cache.instance;
  } catch (error) {
    printError('[initCache] $error');
    return null;
  }
}

deleteCache({String? context = StoreContext.DEFAULT}) async {
  try {
    late var cacheFactory;
    var cacheKeyId = Cache.keyLocation;
    var cacheLocation = Cache.databaseLocation;

    if (context!.isNotEmpty) {
      cacheKeyId = '$context-${Cache.keyLocation}';
      cacheLocation = '$context-${Cache.databaseLocation}';
    }

    if (Platform.isAndroid || Platform.isIOS) {
      final directory = await getApplicationSupportDirectory();
      await directory.create();
      cacheLocation = join(directory.path, cacheLocation);
      cacheFactory = databaseFactoryIo;
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      cacheFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    await cacheFactory.deleteDatabase(cacheLocation);
    await deleteKey(cacheKeyId);
  } catch (error) {
    printError('[initCache] $error');
  }
}

// Closes and saves storage
closeCache(Database? cache) async {
  if (cache != null) {
    cache.close();
  }
}
