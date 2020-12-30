import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

Future<void> saveRooms(
  Map<String, Room> rooms, {
  Database cache,
  Database storage,
}) async {
  final store = StoreRef<String, String>('rooms');
  storage = storage ?? Storage.main;

  return await storage.transaction((txn) async {
    for (Room room in rooms.values) {
      final record = store.record(room.id);
      await record.put(txn, jsonEncode(room));
    }
  });
}

Future<void> deleteRooms(
  Map<String, Room> rooms, {
  Database cache,
  Database storage,
}) async {
  final store = StoreRef<String, String>('rooms');
  storage = storage ?? Storage.main;

  return await storage.transaction((txn) async {
    for (Room room in rooms.values) {
      final record = store.record(room.id);
      await record.delete(txn);
    }
  });
}

Future<Map<String, Room>> loadRooms({
  Database cache,
  Database storage,
  int offset = 0,
  int limit = 10,
}) async {
  final Map<String, Room> rooms = {};

  try {
    final store = StoreRef<String, String>('rooms');
    final count = await store.count(storage);

    final finder = Finder(
      limit: limit,
      offset: offset,
    );

    final roomsPaginated = await store.find(
      storage,
      finder: finder,
    );

    if (roomsPaginated.isEmpty) {
      return rooms;
    }

    for (RecordSnapshot<String, String> record in roomsPaginated) {
      rooms[record.key] = Room.fromJson(json.decode(record.value));
    }

    if (offset < count) {
      rooms.addAll(await loadRooms(
        offset: offset + limit,
        storage: storage,
      ));
    }

    if (rooms.isEmpty) {
      return null;
    }

    printInfo('[rooms] loaded ${rooms.length.toString()}');
    return rooms;
  } catch (error) {
    printError(error.toString(), title: 'loadRooms');
    return null;
  }
}
