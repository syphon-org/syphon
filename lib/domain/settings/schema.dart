import 'package:drift/drift.dart';
import 'package:syphon/global/libs/storage/converters.dart';

///
/// Settings Model (Table)
///
/// Meant to store all setting state in _cold storage_
///
class Settings extends Table {
  TextColumn get id => text().unique()();
  TextColumn get store => text().map(const MapToJsonConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
