import 'dart:io';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/storage/codec.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
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

    var codec = getEncryptSembastCodec(password: 'testing123');

    await storageFactory.deleteDatabase(StorageSecure.storageKeyMain);

    StorageSecure.storageMain = await storageFactory.openDatabase(
      StorageSecure.storageKeyMain,
      codec: codec,
    );
  } catch (error) {
    debugPrint('[initCache] ${error}');
  }
}

Future<void> loadStorage() async {
  StorageSecure.storageData['users'] = await loadUsers(
    storage: StorageSecure.storageMain,
  );
}

// // Closes and saves storage
void closeStorage() async {
  if (StorageSecure.storageMain != null) {
    StorageSecure.storageMain.close();
  }
}
