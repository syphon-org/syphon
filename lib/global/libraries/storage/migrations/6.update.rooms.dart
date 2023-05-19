import 'package:drift/drift.dart';
import 'package:syphon/global/libraries/storage/database.dart';
import 'package:syphon/global/print.dart';

extension Version6 on ColdStorageDatabase {
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          console.info('[MIGRATION] VERSION $from to $to');
          if (from == 5) {
            m.createTable(reactions);
          }
        },
      );
}
