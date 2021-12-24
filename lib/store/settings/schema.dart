import 'package:drift/drift.dart';
import 'package:syphon/storage/converters.dart';

///
/// Settings Model (Table)
///
/// Meant to store all setting state in _cold storage_
///
class Settings extends Table {
  TextColumn get id => text().customConstraint('UNIQUE')();
  TextColumn get store => text().map(const MapToJsonConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
