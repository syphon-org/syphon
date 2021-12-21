import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/context/types.dart';
import 'package:syphon/global/libs/storage/key-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

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
  static String? cacheKey;

  // hot cache refrences
  static Database? instance;

  // inital store caches for reload
  static Map<String, Map?> cacheStores = {};
}

///
/// Init Hot Cache
///
Future<Database?> initCache({AppContext context = const AppContext()}) async {
  try {
    final contextId = context.id;
    var cacheKeyId = Cache.keyLocation;
    var cacheLocation = Cache.databaseLocation;

    if (contextId.isNotEmpty) {
      cacheKeyId = '$contextId-${Cache.keyLocation}';
      cacheLocation = '$contextId-${Cache.databaseLocation}';
    }

    cacheLocation = DEBUG_MODE ? 'debug-$cacheLocation' : cacheLocation;

    var cacheFactory;

    // Configure cache encryption/decryption instance
    final cacheKey = await loadKey(cacheKeyId);

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

    printInfo('[initCache] $cacheLocation $cacheKey');

    Cache.cacheKey = cacheKey;
    return await cacheFactory.openDatabase(cacheLocation);
  } catch (error) {
    printError('[initCache] $error');
    return null;
  }
}

deleteCache({AppContext context = const AppContext()}) async {
  try {
    late var cacheFactory;
    final contextId = context.id;

    var cacheKeyId = Cache.keyLocation;
    var cacheLocation = Cache.databaseLocation;

    if (contextId.isNotEmpty) {
      cacheKeyId = '$contextId-${Cache.keyLocation}';
      cacheLocation = '$contextId-${Cache.databaseLocation}';
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
    printError('[deleteCache] $error');
  }
}

// Closes and saves storage
closeCache(Database? cache) async {
  if (cache != null) {
    cache.close();
  }
}
