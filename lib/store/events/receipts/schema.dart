import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/store/events/receipts/model.dart';

class MapToReadConverter extends TypeConverter<Map<String, dynamic>?, String> {
  const MapToReadConverter();

  @override
  Map<String, int>? mapToDart(String? fromDb) {
    return json.decode(fromDb!) as Map<String, int>?;
  }

  @override
  String? mapToSql(Map<String, dynamic>? value) {
    return json.encode(value);
  }

  @override
  Map<String, dynamic>? fromSql(String fromDb) {
    // TODO: implement fromSql
    throw UnimplementedError();
  }

  @override
  String toSql(Map<String, dynamic>? value) {
    // TODO: implement toSql
    throw UnimplementedError();
  }
}

///
/// Reactions Model (Table)
///
/// Meant to store reactions in _cold storage_
///
@UseRowClass(Receipt)
class Receipts extends Table {
  // Event Base Date
  TextColumn get eventId => text().unique()();
  IntColumn get latestRead => integer().nullable()();
  TextColumn get userReads => text().map(const MapToReadConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {eventId};
}
