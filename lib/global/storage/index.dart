import 'dart:io';

import 'package:meta/meta.dart';
import 'package:flutter/material.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/storage/codec.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/user/storage.dart';

class Storage {
  // cold storage references
  static Database main;

  // preloaded cold storage data
  static Map<String, dynamic> storageData = {};

  // storage identifiers
  static const mainKey = '${Values.appNameLabel}-main-storage.db';
}

Future<Database> initStorage() async {
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

    final codec = getEncryptSembastCodec(password: Cache.cryptKey);

    // TODO: make actions have reference to the storage/cache through state
    Storage.main = await storageFactory.openDatabase(
      Storage.mainKey,
      codec: codec,
    );

    return Storage.main;
  } catch (error) {
    debugPrint('[initStorage] $error');
    return null;
  }
}

// // Closes and saves storage
void closeStorage() async {
  if (Storage.main != null) {
    Storage.main.close();
  }
}

Future<void> deleteStorage() async {
  try {
    DatabaseFactory storageFactory;

    if (Platform.isAndroid || Platform.isIOS) {
      storageFactory = getDatabaseFactorySqflite(
        sqflite.databaseFactory,
      );
    }

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      storageFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    Storage.main = await storageFactory.deleteDatabase(
      Storage.mainKey,
    );
  } catch (error) {
    printError('[deleteStorage] ${error.toString()}');
  }
}

Future<Map<String, Map<dynamic, dynamic>>> loadStorage(Database storage) async {
  // load all rooms from cold storages
  final rooms = await loadRooms(
    storage: storage,
  );

  final users = await loadUsers(
    storage: storage,
  );

  // load message using rooms loaded from cold storage
  Map<String, List<Message>> messages = new Map();
  for (Room room in rooms.values) {
    messages[room.id] = await loadMessages(
      room.messageIds,
      storage: storage,
      encrypted: room.encryptionEnabled,
    );
    printError(
      '[loadMessages] ${messages[room.id]?.length} ${room.name} loaded',
    );
  }

  return {
    'users': users,
    'rooms': rooms,
    'messages': messages.isNotEmpty ? messages : null,
  };
}
