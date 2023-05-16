import 'dart:io';

import 'package:drift/drift.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/rooms/room/schema.dart';
import 'package:syphon/global/libs/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Room Queries
///
extension RoomQueries on StorageDatabase {
  Future<void> insertRooms(List<Room> rooms) {
    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return batch(
        (batch) => batch.insertAll(
          this.rooms,
          rooms,
          mode: InsertMode.insertOrReplace,
        ),
      );
    }
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(this.rooms, rooms),
    );
  }

  Future<void> deleteRooms(List<Room> rooms) {
    final ids = rooms.map((r) => r.id).toList();

    return batch((batch) {
      for (final id in ids) {
        batch.deleteWhere(this.rooms, (Rooms room) => room.id.equals(id));
      }
    });
  }

  Future<Room> selectRoom(String roomId) {
    return (select(rooms)
          ..where((tbl) => tbl.id.equals(roomId))
          ..limit(1))
        .getSingle();
  }

  Future<List<Room>> selectRooms(List<String> ids, {int offset = 0, int limit = 0}) {
    return (select(rooms)
          ..where((tbl) => tbl.id.isIn(ids))
          ..limit(limit, offset: offset))
        .get();
  }

  // Select all non-archived rooms
  Future<List<Room>> selectRoomsAll({int offset = 0, int limit = 0}) {
    return (select(rooms)..where((tbl) => tbl.archived.equals(false))).get();
  }

  Future<List<Room>> selectRoomsArchived({int offset = 0, int limit = 0}) {
    return (select(rooms)..where((tbl) => tbl.archived.equals(true))).get();
  }
}

Future saveRoom(
  Room room, {
  required StorageDatabase storage,
}) async {
  return storage.insertRooms([room]);
}

Future saveRooms(
  Map<String, Room> rooms, {
  required StorageDatabase storage,
}) async {
  return storage.insertRooms(rooms.values.toList());
}

Future deleteRooms(
  Map<String, Room> rooms, {
  required StorageDatabase storage,
}) async {
  return storage.deleteRooms(rooms.values.toList());
}

Future<Map<String, Room>> loadRooms({
  int offset = 0,
  int limit = 10,
  required StorageDatabase storage,
}) async {
  Map<String, Room> rooms = {};

  try {
    final loaded = await storage.selectRoomsAll();
    log.info('[rooms] loaded ${loaded.length}');

    rooms = Map<String, Room>.fromIterable(
      loaded,
      key: (room) => room.id,
      value: (room) {
        return room as Room;
      },
    );
  } catch (error) {
    log.error(error.toString(), title: 'loadRooms');
  }

  return rooms;
}
