import 'dart:io';

import 'package:moor/ffi.dart';
import 'package:moor/moor.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/key-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/messages/schema.dart';

part 'database.g.dart';

LazyDatabase openDatabase(String context) {
  return LazyDatabase(() async {
    var storageKeyId = Storage.keyLocation;
    var storageLocation = Storage.sqliteLocation; // TODO: convert after total moor conversion

    // prepend with context
    storageKeyId = '$context-$storageKeyId';
    storageLocation = '$context-$storageLocation';

    // prepend with debug mode
    storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

    // Configure cache encryption/decryption instance
    final storageKey = await loadKey(storageKeyId);

    File? filePath;

    if (Platform.isAndroid || Platform.isIOS) {
      final dbFolder = await getApplicationDocumentsDirectory();
      filePath = File(path.join(dbFolder.path, storageLocation));
    }

    printInfo('initColdStorage $storageLocation $storageKey');

    return VmDatabase(
      filePath!,
      logStatements: DEBUG_MODE,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '$storageKey';");
      },
    );
  });
}

@UseMoor(tables: [Messages])
class StorageDatabase extends _$StorageDatabase {
  // we tell the database where to store the data with this constructor
  StorageDatabase(String context) : super(openDatabase(context));

  // you should bump this number whenever you change or add a table definition. Migrations
  // are covered later in this readme.
  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
      // beforeOpen: (openingDetails) async {
      //   print("RUNNING BEFORE OPEN $DEBUG_MODE");
      //   if (DEBUG_MODE) {
      //     final m = createMigrator(); // changed to this
      //     for (final table in allTables) {
      //       await m.deleteTable(table.actualTableName);
      //       await m.createTable(table);
      //     }
      //   }
      // },
      );
}
