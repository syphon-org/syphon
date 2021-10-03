import 'package:moor/moor.dart';
import 'package:syphon/store/media/model.dart';

///
/// Messages Model (Table)
///
/// Meant to store messages in _cold storage_
///
@UseRowClass(Media)
class Medias extends Table {
  TextColumn get mxcUri => text().customConstraint('UNIQUE')();
  BlobColumn get data => blob().nullable()();

  @override
  Set<Column> get primaryKey => {mxcUri};
}
