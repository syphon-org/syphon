import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/codec.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/media/storage.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/user/storage.dart';

class Storage {
  // cold storage references
  static Database? main;

  // preloaded cold storage data
  static Map<String, dynamic> storageData = {};

  // storage identifiers
  static const mainLocation = '${Values.appNameLabel}-main-storage${kReleaseMode ? '' : '-debug'}.db';
}

Future<Database?> initStorage() async {
  try {
    DatabaseFactory? storageFactory;

    var version;

    if (Platform.isAndroid || Platform.isIOS) {
      version = 1;
      // always open cold storage as sqflite
      storageFactory = getDatabaseFactorySqflite(
        sqflite.databaseFactory,
      );
    }

    /// Supports Windows/Linux/MacOS for now.
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      version = 2;
      storageFactory = getDatabaseFactorySqflite(
        sqflite_ffi.databaseFactoryFfi,
      );
    }

    if (storageFactory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    final codec = getEncryptSembastCodec(password: Cache.cryptKey!);

    Storage.main = await storageFactory.openDatabase(
      Storage.mainLocation,
      codec: codec,
      version: version,
    );

    return Storage.main;
  } catch (error) {
    print('[initStorage] $error');
    return null;
  }
}

// // Closes and saves storage
closeStorage() async {
  if (Storage.main != null) {
    Storage.main!.close();
  }
}

Future deleteStorage() async {
  try {
    late DatabaseFactory storageFactory;

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

    await storageFactory.deleteDatabase(Storage.mainLocation);

    Storage.main = null;
  } catch (error) {
    printError('[deleteStorage] ${error.toString()}');
  }
}

///
/// Load Storage
///
/// bulk loads cold storage objects to RAM, this can
/// be much more specific and performant
///
/// for example, only load users that are known to be
/// involved in stored messages/events
///
/// TODO: need pagination for pretty much all of these
Future<Map<String, dynamic>> loadStorage(Database storage) async {
  try {
    final auth = await loadAuth(storage: storage);
    final rooms = await loadRooms(storage: storage);
    final users = await loadUsers(storage: storage);
    final media = await loadMediaAll(storage: storage);
    final crypto = await loadCrypto(storage: storage);
    final settings = await loadSettings(storage: storage);
    final redactions = await loadRedactions(storage: storage);

    Map<String, List<Message>> messages = {};
    Map<String, List<Reaction>> reactions = {};
    Map<String, Map<String, ReadReceipt>> receipts = {};

    for (Room room in rooms.values) {
      messages[room.id] = await loadMessages(
        room.messageIds,
        storage: storage,
      );

      reactions.addAll(await loadReactions(
        room.messageIds,
        storage: storage,
      ));

      receipts[room.id] = await loadReceipts(
        room.messageIds,
        storage: storage,
      );
    }

    return {
      'auth': auth,
      'users': users.isNotEmpty ? users : null,
      'rooms': rooms,
      'media': media,
      'crypto': crypto,
      'messages': messages.isNotEmpty ? messages : null,
      'reactions': reactions,
      'redactions': redactions,
      'receipts': receipts,
      'settings': settings,
    };
  } catch (error) {
    printError('[loadStorage]  ${error.toString()}');
    return {};
  }
}
