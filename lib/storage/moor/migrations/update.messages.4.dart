import 'package:moor/moor.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/moor/database.dart';

extension Version4 on StorageDatabase {
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          printInfo('RUNNING MIGRATION VERSION $from to $to');
          if (from == 3) {
            await m.renameColumn(messages, 'filename', messages.file);
            await m.addColumn(messages, messages.url);
          }
        },
      );
}