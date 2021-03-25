import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/model.dart';
import 'package:syphon/store/events/redactions/model.dart';

///
/// Save Events
///
/// TODO: stub for reference, not needed
/// event types have their own tables
///
Future<void> saveEvents(
  List<Event> events, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.EVENTS);

  return await storage.transaction((txn) async {
    for (Event event in events) {
      final record = store.record(event.id);
      await record.put(txn, json.encode(event));
    }
  });
}

///
/// Delete Events
///
/// TODO: stub for reference, not needed
/// event types have their own tables
///
Future<void> deleteEvents(
  List<Event> events, {
  Database storage,
}) async {
  final stores = [
    StoreRef<String, String>(StorageKeys.EVENTS),
  ];

  return await Future.wait(stores.map((store) async {
    return await storage.transaction((txn) async {
      for (Event event in events) {
        final record = store.record(event.id);
        await record.delete(storage);
      }
    });
  }));
}
