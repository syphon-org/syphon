import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

///
/// Save Receipts
///
///
Future<void> saveReceipts(
  String roomId,
  Map<String, ReadReceipt> receipts, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.RECEIPTS);

  return await storage.transaction((txn) async {
    final record = store.record(roomId);
    await record.put(txn, json.encode(receipts));
  });
}

///
/// Load Receipts
///
///
Future<Map<String, ReadReceipt>> loadReceipts({
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.RECEIPTS);

  final redactions = Map<String, ReadReceipt>();

  final roomReceipts = await store.find(storage);

  for (RecordSnapshot<String, String> record in roomReceipts) {
    redactions[record.key] = ReadReceipt.fromJson(
      json.decode(record.value),
    );
  }

  return redactions;
}
