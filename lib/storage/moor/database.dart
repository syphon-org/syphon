import 'dart:ffi';
import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:syphon/global/libs/storage/key-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/schema.dart';

///
/// Change imported migration strategy extension on schema change
///
// ignore: unused_import
import 'package:syphon/storage/moor/migrations/update.messages.4.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/schema.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/schema.dart';

part 'database.g.dart';

void _openOnAndroid() {
  try {
    open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
  } catch (error) {
    printError(error.toString());
  }
}

void _openOnLinux() {
  try {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final libraryNextToScript = File('${scriptDir.path}/sqlite3.so');
    final lib = DynamicLibrary.open(libraryNextToScript.path);

    open.overrideFor(OperatingSystem.linux, () => lib);
  } catch (error) {
    printError(error.toString());
  }
}

LazyDatabase openDatabase(String context) {
  return LazyDatabase(() async {
    var storageKeyId = Storage.keyLocation;
    var storageLocation = Storage.sqliteLocation; // TODO: convert after total moor conversion

    // prepend with context
    storageKeyId = '$context-$storageKeyId';
    storageLocation = '$context-$storageLocation';

    // prepend with debug mode
    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    File? filePath;

    if (Platform.isLinux) {
      _openOnLinux();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      if (Platform.isAndroid) {
        _openOnAndroid();
      }

      final dbFolder = await getApplicationSupportDirectory();
      filePath = File(path.join(dbFolder.path, storageLocation));
    }

    // Configure cache encryption/decryption instance
    final storageKey = await loadKey(storageKeyId);

    return VmDatabase(
      filePath!,
      logStatements: false, // DEBUG_MODE,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$storageKey';");
      },
    );
  });
}

@UseMoor(tables: [Messages, Decrypted, Rooms, Users])
class StorageDatabase extends _$StorageDatabase {
  // we tell the database where to store the data with this constructor
  StorageDatabase(String context) : super(openDatabase(context));

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 4;
}
