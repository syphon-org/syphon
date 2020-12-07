import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/rooms/room/model.dart';

Future<void> saveRooms(
  Map<String, Room> rooms, {
  Database cache,
  Database storage,
}) async {
  final store = StoreRef<String, String>('rooms');

  await storage.transaction((txn) async {
    for (Room room in rooms.values) {
      final record = store.record(room.id);
      await record.put(txn, jsonEncode(room));
    }
  });
}

Future<Map<String, Room>> loadRooms({
  Database cache,
  Database storage,
  int offset = 0,
}) async {
  final Map<String, Room> rooms = {};

  try {
    const limit = 10;
    final store = StoreRef<String, String>('rooms');
    final count = await store.count(storage);

    final finder = Finder(
      limit: limit,
      offset: offset,
    );

    final usersPaginated = await store.find(
      storage,
      finder: finder,
    );

    if (usersPaginated.isEmpty) {
      return rooms;
    }

    for (RecordSnapshot<String, String> record in usersPaginated) {
      rooms[record.key] = Room.fromJson(json.decode(record.value));
    }

    if (offset < count) {
      rooms.addAll(await loadRooms(
        offset: offset + limit,
        storage: storage,
      ));
    }
  } catch (error) {
    printDebug(error.toString());
  }
  printDebug('[rooms] loaded ${rooms.length.toString()}');
  return rooms;
}
