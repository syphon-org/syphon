import 'dart:convert';

import 'package:syphon/global/print.dart';
import 'package:syphon/storage/moor/database.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/schema.dart';

///
/// Room Queries
///
extension RoomQueries on StorageDatabase {
  Future<void> insertRooms(List<Room> rooms) {
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

  // Future<List<Room>> searchRooms(String text, {int offset = 0, int limit = 25}) {
  //   return (select(rooms)
  //         ..where((tbl) => tbl.topic.like('%$text%'))
  //         ..limit(25, offset: offset))
  //       .get();
  // }
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
    printInfo('[rooms] loaded ${loaded.length.toString()}');

    rooms = Map<String, Room>.fromIterable(
      loaded,
      key: (room) => room.id,
      value: (room) {
        try {
          return room as Room;
        } catch (error) {
          printJson(jsonDecode(jsonEncode(room)));
          printError(error.toString(), title: 'loadRooms');
          return Room(id: 'FAILED');
        }
      },
    );
  } catch (error) {
    printError(error.toString(), title: 'loadRooms');
  }

  return rooms;
}
