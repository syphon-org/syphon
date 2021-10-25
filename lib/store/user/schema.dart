import 'package:drift/drift.dart';
import 'package:syphon/store/user/model.dart';

///
/// Users Schema (Table)
///
/// Meant to store users in _cold storage_
///
@UseRowClass(User)
class Users extends Table {
  // break

  // TODO: rename User model to id instead of userId
  TextColumn get userId => text().named('id').customConstraint('UNIQUE')();
  TextColumn get deviceId => text().nullable()(); // current device ID for auth
  TextColumn get idserver => text().nullable()();
  TextColumn get homeserver => text().nullable()();
  TextColumn get homeserverName => text().nullable()();
  TextColumn get accessToken => text().nullable()();
  TextColumn get displayName => text().nullable()();
  TextColumn get avatarUri => text().nullable()();

  @override
  Set<Column> get primaryKey => {userId};
}
