import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:syphon/domain/media/encryption.dart';
import 'package:syphon/domain/media/model.dart';

class EncryptInfoToJsonConverter extends NullAwareTypeConverter<EncryptInfo?, String> {
  const EncryptInfoToJsonConverter();

  @override
  EncryptInfo? requireFromSql(String fromDb) {
    return EncryptInfo.fromJson(json.decode(fromDb ?? '{}') ?? {});
  }

  @override
  String requireToSql(EncryptInfo? value) {
    return json.encode(value);
  }
}

///
/// Messages Model (Table)
///
/// Meant to store messages in _cold storage_
///
@UseRowClass(Media)
class Medias extends Table {
  TextColumn get mxcUri => text().unique()();
  BlobColumn get data => blob().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get info => text().map(const EncryptInfoToJsonConverter()).nullable()();

  @override
  Set<Column> get primaryKey => {mxcUri};
}
