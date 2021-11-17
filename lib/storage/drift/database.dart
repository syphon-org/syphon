import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_library_windows/sqlcipher_library_windows.dart';
import 'package:sqlite3/open.dart';
import 'package:syphon/global/libs/storage/key-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/drift/converters.dart';
// ignore: unused_import
import 'package:syphon/storage/drift/migrations/update.messages.5.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/schema.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/media/schema.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/schema.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/schema.dart';

part 'database.g.dart';

void _openOnIOS() {
  try {
    open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());
  } catch (error) {
    printError(error.toString());
  }
}

void _openOnAndroid() {
  try {
    open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
  } catch (error) {
    printError(error.toString());
  }
}

void _openOnLinux() {
  try {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'));
    return;
  } catch (_) {
    try {
      // fallback to sqlite if unavailable
      final scriptDir = File(Platform.script.toFilePath()).parent;
      final libraryNextToScript = File('${scriptDir.path}/sqlite3.so');
      final lib = DynamicLibrary.open(libraryNextToScript.path);

      open.overrideFor(OperatingSystem.linux, () => lib);
    } catch (error) {
      printError(error.toString());
      rethrow;
    }
  }
}

LazyDatabase openDatabase(String context) {
  return LazyDatabase(() async {
    var storageKeyId = Storage.keyLocation;
    var storageLocation = Storage.sqliteLocation; // TODO: convert after total drift conversion

    // prepend with context
    storageKeyId = '$context-$storageKeyId';
    storageLocation = '$context-$storageLocation';

    // prepend with debug mode
    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    // get application support directory for all platforms

    var filePath;

    final dbFolder = await getApplicationSupportDirectory();
    filePath = File(path.join(dbFolder.path, storageLocation));

    if (Platform.isWindows) {
      openSQLCipherOnWindows();
    }

    if (Platform.isIOS || Platform.isMacOS) {
      _openOnIOS();
    }

    if (Platform.isLinux) {
      _openOnLinux();
    }

    if (Platform.isAndroid) {
      _openOnAndroid();
    }

    // Configure cache encryption/decryption instance
    final storageKey = await loadKey(storageKeyId);

    return NativeDatabase(
      filePath,
      logStatements: false, // DEBUG_MODE,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$storageKey';");
      },
    );
  });
}

@DriftDatabase(tables: [Messages, Decrypted, Rooms, Users, Medias])
class StorageDatabase extends _$StorageDatabase {
  // we tell the database where to store the data with this constructor
  StorageDatabase(String context) : super(openDatabase(context));

  // this is the new constructor
  StorageDatabase.connect(DatabaseConnection connection) : super.connect(connection);

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          printInfo('[MIGRATION] VERSION $from to $to');
          if (from == 4) {
            await m.addColumn(messages, messages.editIds);
            await m.addColumn(messages, messages.batch);
            await m.addColumn(messages, messages.prevBatch);
            await m.renameColumn(rooms, 'last_hash', rooms.lastBatch);
            await m.renameColumn(rooms, 'prev_hash', rooms.prevBatch);
            await m.renameColumn(rooms, 'next_hash', rooms.nextBatch);
          }
        },
      );
}
