import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_library_windows/sqlcipher_library_windows.dart';
import 'package:sqlite3/open.dart';
import 'package:syphon/context/auth.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/domain/auth/schema.dart';
import 'package:syphon/domain/crypto/schema.dart';
import 'package:syphon/domain/crypto/sessions/schema.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/messages/schema.dart';
import 'package:syphon/domain/events/reactions/model.dart';
import 'package:syphon/domain/events/reactions/schema.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/domain/events/receipts/schema.dart';
import 'package:syphon/domain/media/encryption.dart';
import 'package:syphon/domain/media/model.dart';
import 'package:syphon/domain/media/schema.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/room/schema.dart';
import 'package:syphon/domain/settings/schema.dart';
import 'package:syphon/domain/sync/schema.dart';
import 'package:syphon/domain/user/model.dart';
import 'package:syphon/domain/user/schema.dart';
import 'package:syphon/global/libraries/secure-storage/key-storage.dart';
import 'package:syphon/global/libraries/storage/converters.dart';
import 'package:syphon/global/libraries/storage/index.dart';
import 'package:syphon/global/libraries/storage/models.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

part 'database.g.dart';

void _openOnIOS() {
  try {
    open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());
  } catch (error) {
    console.error(error.toString());
  }
}

void _openOnAndroid() {
  try {
    open.overrideFor(OperatingSystem.android, () => DynamicLibrary.open('libsqlcipher.so'));
  } catch (error) {
    console.error(error.toString());
  }
}

void _openOnLinux() {
  try {
    open.overrideFor(OperatingSystem.linux, () => DynamicLibrary.open('libsqlcipher.so'));
    return;
  } catch (_) {
    console.error(_.toString());
    try {
      // fallback to sqlite if unavailable
      final scriptDir = File(Platform.script.toFilePath()).parent;
      final libraryNextToScript = File('${scriptDir.path}/sqlite3.so');
      final lib = DynamicLibrary.open(libraryNextToScript.path);

      open.overrideFor(OperatingSystem.linux, () => lib);
    } catch (error) {
      console.error(error.toString());
      rethrow;
    }
  }
}

void initDatabase() {
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

  return;
}

Future<DatabaseInfo> findDatabase(AppContext context, {String pin = Values.empty, SendPort? port}) async {
  var storageKeyId = Storage.keyLocation;
  var storageLocation = Storage.sqliteLocation;

  final contextId = context.id;

  // prepend with context - always even if empty
  if (contextId.isNotEmpty) {
    storageKeyId = '$contextId-$storageKeyId';
    storageLocation = '$contextId-$storageLocation';
  }

  // prepend with debug mode
  storageLocation = DEBUG_MODE ? 'debug-$storageLocation' : storageLocation;

  // get application support directory for all platforms
  final dbFolder = await getApplicationSupportDirectory();
  final filePath = File(path.join(dbFolder.path, storageLocation));

  // Configure cache encryption/decryption instance
  var storageKey = await loadKey(storageKeyId);

  final isLockedContext = context.id.isNotEmpty && context.secretKeyEncrypted.isNotEmpty && pin.isNotEmpty;

  // TODO: move into the isolate?
  if (isLockedContext) {
    storageKey = await unlockSecretKey(context, pin);
  }

  return DatabaseInfo(
    key: storageKey,
    path: filePath.path,
    port: port,
  );
}

// This needs to be a top-level method because it's run on a background isolate
// When using a Flutter plugin like `path_provider` to determine the path,
void _openDatabaseBackground(DatabaseInfo info) {
  initDatabase();

  final driftIsolate = DriftIsolate.inCurrent(
    () => DatabaseConnection(
      NativeDatabase(
        File(info.path),
        logStatements: false,
        setup: (rawDb) {
          rawDb.execute("PRAGMA key = '${info.key}';");
        },
      ),
    ),
  );

  if (info.port == null) {
    return;
  }

  // inform the starting isolate about this, so that it can call .connect()
  info.port!.send(driftIsolate);
}

Future<DriftIsolate> spawnDatabaseIsolate(AppContext context, {String pin = Values.empty}) async {
  final receivePort = ReceivePort();

  final info = await findDatabase(context, pin: pin, port: receivePort.sendPort);

  await Isolate.spawn(
    _openDatabaseBackground,
    info,
  );

  // _startBackground will send the DriftIsolate to this ReceivePort
  return await receivePort.first as DriftIsolate;
}

ColdStorageDatabase openDatabaseThreaded(AppContext context, {String pin = Values.empty}) {
  final connection = DatabaseConnection.delayed(
    () async {
      final isolate = await spawnDatabaseIsolate(context, pin: pin);
      // ignore: unnecessary_await_in_return
      return await isolate.connect();
    }(),
  );

  return ColdStorageDatabase.connect(connection);
}

LazyDatabase openDatabase(AppContext context, {String pin = Values.empty}) {
  return LazyDatabase(() async {
    initDatabase();

    final info = await findDatabase(context, pin: pin);

    return NativeDatabase(
      File(info.path),
      logStatements: false,
      setup: (rawDb) {
        rawDb.execute("PRAGMA key = '${info.key}';");
      },
    );
  });
}

@DriftDatabase(
  tables: [
    Messages,
    Decrypted,
    Rooms,
    Users,
    Medias,
    Reactions,
    Receipts,
    Auths,
    Syncs,
    Cryptos,
    MessageSessions,
    KeySessions,
    Settings,
  ],
)
class ColdStorageDatabase extends _$ColdStorageDatabase {
  ColdStorageDatabase(AppContext context, {String pin = ''}) : super(openDatabase(context, pin: pin));

  ColdStorageDatabase.connect(super.connection) : super.connect();

  // you should bump this number whenever you change or add a table definition.
  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          console.info('[MIGRATION] VERSION $from to $to');

          if (from == 8) {
            await m.addColumn(messages, messages.hasLink);
            await m.addColumn(messages, decrypted.hasLink);
          }
          if (from == 7) {
            await m.createTable(keySessions);
            await m.createTable(messageSessions);
          }
          if (from == 6) {
            await m.createTable(syncs);
          }
          if (from == 5) {
            await m.createTable(auths);
            await m.createTable(cryptos);
            await m.createTable(settings);
            await m.createTable(receipts);
            await m.createTable(reactions);
          }
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
