import 'dart:io';

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/codec.dart';
import 'package:syphon/global/values.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/actions.dart';
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/media/storage.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/storage.dart';

class Storage {
  // cold storage references
  static Database main;

  // preloaded cold storage data
  static Map<String, dynamic> storageData = {};

  // storage identifiers
  static const mainLocation = '${Values.appNameLabel}-main-storage.db';
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

    if (storageFactory == null) {
      throw UnsupportedError(
        'Sorry, Syphon does not support your platform yet. Hope to do so soon!',
      );
    }

    final codec = getEncryptSembastCodec(password: Cache.cryptKey);

    Storage.main = await storageFactory.openDatabase(
      Storage.mainLocation,
      codec: codec,
    );

    return Storage.main;
  } catch (error) {
    printDebug('[initStorage] $error');
    return null;
  }
}

///
/// Close Storage
///
/// Closes and saves storage
///
void closeStorage() async {
  if (Storage.main != null) {
    Storage.main.close();
  }
}

//
// Delete Storage
//
// delete essential cold storage, usually done
// when logging out of an account
//
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
      Storage.mainLocation,
    );
  } catch (error) {
    printError('[deleteStorage] ${error.toString()}');
  }
}

//
// Load Storage
//
// essential cold storage backup needed in case hot
// cache becomes corrupted (issue with closing the application)
// with the json is serializing
//
// TODO: make cold cache failure aware
//
Future<Map<String, dynamic>> loadStorage(Database storage) async {
  try {
    final auth = await loadAuth(storage: storage);
    final rooms = await loadRooms(storage: storage);
    final crypto = await loadCrypto(storage: storage);
    final settings = await loadSettings(storage: storage);

    return {
      StorageKeys.AUTH: auth,
      StorageKeys.ROOMS: rooms,
      StorageKeys.CRYPTO: crypto,
      StorageKeys.SETTINGS: settings,
    };
  } catch (error) {
    printError('[loadStorage]  ${error.toString()}');
    return {};
  }
}

//
// Load Storage (Async)
//
// finishes loading cold storage objects to RAM, this can
// be much more specific and performant
//
// for example, only load users that are known to be
// involved in stored messages/events
//
// TODO: need pagination for pretty much all of these
//
void loadStorageAsync(Database storage, Store<AppState> store) async {
  try {
    store.dispatch(ToggleLoadingStorage(loading: true));

    final rooms = await loadRooms(storage: storage);
    final users = await loadUsers(storage: storage);
    final media = await loadMediaAll(storage: storage);
    final redactions = await loadRedactions(storage: storage);

    var messages = Map<String, List<Message>>();
    var reactions = Map<String, List<Reaction>>();
    var receipts = Map<String, Map<String, ReadReceipt>>();

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

    final loaded = {
      StorageKeys.USERS: users,
      StorageKeys.ROOMS: rooms,
      StorageKeys.MEDIA: media,
      StorageKeys.MESSAGES: messages.isNotEmpty ? messages : null,
      StorageKeys.REACTIONS: reactions,
      StorageKeys.REDACTIONS: redactions,
      StorageKeys.RECEIPTS: receipts,
    };

    for (MapEntry data in loaded.entries) {
      if (data.value != null) {
        switch (data.key) {
          case StorageKeys.USERS:
            store.dispatch(SetUsers(users: data.value));
            break;
          case StorageKeys.ROOMS:
            store.dispatch(SetRooms(
              rooms: List.from((data.value as Map).values),
            ));
            break;
          case StorageKeys.MEDIA:
            store.dispatch(LoadMedia(media: data.value));
            break;
          case StorageKeys.MESSAGES:
            store.dispatch(LoadMessages(messagesMap: data.value));
            break;
          case StorageKeys.REACTIONS:
            store.dispatch(LoadReactions(reactionsMap: data.value));
            break;
          case StorageKeys.RECEIPTS:
            store.dispatch(LoadReceipts(receiptsMap: data.value));
            break;
          case StorageKeys.REDACTIONS:
            store.dispatch(LoadRedactions(redactionsMap: data.value));
            break;
          default:
            break;
        }
      }
    }

    store.dispatch(ToggleLoadingStorage(loading: false));
  } catch (error) {
    printError('[loadStorageAsync]  ${error.toString()}');
  }
}
