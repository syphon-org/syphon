import 'package:drift/drift.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';

extension Version6 on StorageDatabase {
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) {
          return m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          printInfo('[MIGRATION] VERSION $from to $to');
          if (from == 5) {
            m.createTable(reactions);
          }
        },
      );
}
