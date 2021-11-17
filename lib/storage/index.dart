import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/context/types.dart';
import 'package:syphon/global/libs/storage/key-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/storage/sembast/codec.dart';
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/media/storage.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/user/storage.dart';

class Storage {
  // cache key identifiers
  static const keyLocation = '${Values.appLabel}@storageKey';

  // storage identifiers
  static const databaseLocation = '${Values.appLabel}-main-storage.db';

  // storage identifiers
  static const sqliteLocation = '${Values.appLabel}-cold-storage.db';

  // cold storage references
  static Database? instance;
  static StorageDatabase? database;
}

Future<StorageDatabase> initColdStorage({String? context = AppContext.DEFAULT}) async {
  final StorageDatabase database = await Future.value(StorageDatabase(context!)); // never null ^
  Storage.database = database;
  return database;
}

Future closeColdStorage(StorageDatabase? storage) async {
  if (storage != null) {
    storage.close();
  }
}

Future deleteColdStorage({String? context = AppContext.DEFAULT}) async {
  try {
    var storageLocation = Storage.sqliteLocation;

    if (context!.isNotEmpty) {
      storageLocation = '$context-$storageLocation';
    }

    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    final appDir = await getApplicationSupportDirectory();
    final file = File(path.join(appDir.path, storageLocation));
    await file.delete();
  } catch (error) {
    printError('[deleteColdStorage] ${error.toString()}');
  }
}

Future<Database?> initStorage({String? context = AppContext.DEFAULT}) async {
  try {
    var storageKeyId = Storage.keyLocation;
    var storageLocation = Storage.databaseLocation;

    if (context!.isNotEmpty) {
      storageKeyId = '$context-$storageKeyId';
      storageLocation = '$context-$storageLocation';
    }

    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    const version = 2;
    var storageFactory;

    // Configure cache encryption/decryption instance
    final storageKey = await loadKey(storageKeyId);

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

    if (storageFactory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    printInfo('[initStorage] $storageLocation $storageKey');

    final codec = getEncryptSembastCodec(password: storageKey);

    final openedDatabase = await storageFactory.openDatabase(
      storageLocation,
      codec: codec,
      version: version,
    );

    Storage.instance = openedDatabase;
    return openedDatabase;
  } catch (error) {
    printDebug('[initStorage] $error');
    return null;
  }
}

// Closes and saves storage
closeStorage(Database? database) async {
  if (database != null) {
    database.close();
  }
}

deleteStorage({String? context = AppContext.DEFAULT}) async {
  try {
    var storageKeyId = Storage.keyLocation;
    var storageLocation = Storage.databaseLocation;

    if (context!.isNotEmpty) {
      storageKeyId = '$context-$storageKeyId';
      storageLocation = '$context-$storageLocation';
    }

    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

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

    await storageFactory.deleteDatabase(storageLocation);
    await deleteKey(storageKeyId);
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
Future<Map<String, dynamic>> loadStorage(Database storageOld, StorageDatabase storage) async {
  try {
    final auth = await loadAuth(storage: storageOld);
    final crypto = await loadCrypto(storage: storageOld);
    final settings = await loadSettings(storage: storageOld);
    final redactions = await loadRedactions(storage: storageOld);

    final rooms = await loadRooms(storage: storage);
    // final users = await loadUsers(storage: storage);
    final media = await loadMediaAll(storage: storage);

    final userIds = <String>[];
    final messages = <String, List<Message>>{};
    final decrypted = <String, List<Message>>{};
    final reactions = <String, List<Reaction>>{};
    final receipts = <String, Map<String, ReadReceipt>>{};

    for (final Room room in rooms.values) {
      messages[room.id] = await loadMessagesRoom(
        room.id,
        storage: storage,
      );

      decrypted[room.id] = await loadDecryptedRoom(
        room.id,
        storage: storage,
      );

      final currentUserIds =
          (messages[room.id] ?? []).map((message) => message.sender ?? '').toList();

      userIds.addAll(currentUserIds);

      reactions.addAll(await loadReactions(
        room.messageIds,
        storage: storageOld,
      ));

      receipts[room.id] = await loadReceipts(
        room.messageIds,
        storage: storageOld,
      );
    }

    final users = await loadUsers(
      storage: storage,
      ids: userIds,
    );

    return {
      StorageKeys.AUTH: auth,
      StorageKeys.USERS: users,
      StorageKeys.ROOMS: rooms,
      StorageKeys.MEDIA: media,
      StorageKeys.CRYPTO: crypto,
      StorageKeys.MESSAGES: messages,
      StorageKeys.DECRYPTED: decrypted,
      StorageKeys.REACTIONS: reactions,
      StorageKeys.REDACTIONS: redactions,
      StorageKeys.RECEIPTS: receipts,
      StorageKeys.SETTINGS: settings,
    };
  } catch (error) {
    printError('[loadStorage]  ${error.toString()}');
    return {};
  }
}
