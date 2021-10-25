import 'dart:convert';

import 'package:drift/drift.dart';

class MapToJsonConverter extends TypeConverter<Map<String, dynamic>?, String> {
  const MapToJsonConverter();

  @override
  Map<String, dynamic>? mapToDart(String? fromDb) {
    return json.decode(fromDb!) as Map<String, dynamic>?;
  }

  @override
  String? mapToSql(Map<String, dynamic>? value) {
    return json.encode(value);
  }
}
