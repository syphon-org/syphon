import 'dart:io';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/storage/codec.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/user/storage.dart';

class StorageSecure {
  // cold storage references
  static Database storageMain;

  // preloaded cold storage data
  static Map<String, dynamic> storageData = {};

  // storage identifiers
  static const storageKeyMain = '${Values.appNameLabel}-main-storage.db';
}

Future<void> initStorage() async {
  try {
    DatabaseFactory storageFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      // always open cold storage as sqflite
      storageFactory = getDatabaseFactorySqflite(
        sqflite.databaseFactory,
      );
    }

    /// Supports Windows/Linux/MacOS for now.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      storageFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    if (factory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    final codec = getEncryptSembastCodec(password: CacheSecure.cryptKey);

    StorageSecure.storageMain = await storageFactory.openDatabase(
      StorageSecure.storageKeyMain,
      codec: codec,
    );
  } catch (error) {
    debugPrint('[initStorage] $error');
  }
}

Future<void> loadStorage() async {
  StorageSecure.storageData = {
    'users': await loadUsers(
      storage: StorageSecure.storageMain,
    ),
    'rooms': await loadRooms(
      storage: StorageSecure.storageMain,
    )
  };
}

// // Closes and saves storage
void closeStorage() async {
  if (StorageSecure.storageMain != null) {
    StorageSecure.storageMain.close();
  }
}
