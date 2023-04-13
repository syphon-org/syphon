import 'dart:convert';

import 'package:drift/drift.dart';

class MapToJsonConverter extends NullAwareTypeConverter<Map<String, dynamic>?, String> {
  const MapToJsonConverter();

  @override
  Map<String, dynamic>? mapToDart(String? fromDb) {
    return json.decode(fromDb!) as Map<String, dynamic>?;
  }

  @override
  String? mapToSql(Map<String, dynamic>? value) {
    return json.encode(value);
  }

  @override
  Map<String, dynamic>? requireFromSql(String fromDb) {
    // TODO: implement requireFromSql
    throw UnimplementedError();
  }

  @override
  String requireToSql(Map<String, dynamic>? value) {
    // TODO: implement requireToSql
    throw UnimplementedError();
  }
}

class ListToTextConverter extends TypeConverter<List<String>, String> {
  const ListToTextConverter();

  @override
  List<String> mapToDart(String? fromDb) {
    return List<String>.from(json.decode(fromDb!) ?? const []);
  }

  @override
  String mapToSql(List<String>? value) {
    try {
      return json.encode(value);
    } catch (error) {
      return '[]';
    }
  }

  @override
  List<String> fromSql(String fromDb) {
    // TODO: implement fromSql
    throw UnimplementedError();
  }

  @override
  String toSql(List<String> value) {
    // TODO: implement toSql
    throw UnimplementedError();
  }
}
