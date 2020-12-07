import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqflite_sqlcipher;
import 'package:syphon/store/user/storage.dart';

class StorageSecure {
  // cold storage references
  static Database storageMain;
  static sqflite_sqlcipher.Database storageMainEncrypted;

  // preloaded cold storage data
  static Map<String, dynamic> storageData = {};

  // storage identifiers
  static const storageKeyMain = '${Values.appNameLabel}-main-storage';
}

Future<void> initStorage() async {
  try {
    var storageFactory;

    var storagePath = '${StorageSecure.storageKeyMain}.db';

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

    StorageSecure.storageMain = await storageFactory.openDatabase(
      storagePath,
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
