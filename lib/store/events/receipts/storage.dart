import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/redaction/model.dart';

///
/// Save Receipts
///
///
Future<void> saveReceipts(
  Map<String, ReadReceipt> receipts, {
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.RECEIPTS);

  return await storage.transaction((txn) async {
    for (String key in receipts.keys) {
      final record = store.record(key);
      await record.put(txn, json.encode(receipts[key]));
    }
  });
}

///
/// Load Receipts
///
/// Iterates through
///
Future<Map<String, ReadReceipt>> loadReceipts(
  List<String> messageIds, {
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.RECEIPTS);

    final receiptsMap = Map<String, ReadReceipt>();
    final records = await store.records(messageIds).getSnapshots(storage);

    for (RecordSnapshot<String, String> record in records ?? []) {
      if (record != null) {
        final receipt = ReadReceipt.fromJson(await json.decode(record.value));
        receiptsMap.putIfAbsent(record.key, () => receipt);
      }
    }
    return receiptsMap;
  } catch (error) {
    printError(error.toString());
    return Map();
  }
}

///
/// Load Receipts
///
/// Iterates through
///
Future<Map<String, Map<String, ReadReceipt>>> loadReceiptsOLD(
  List<String> messageIds, {
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.RECEIPTS);

    final receipts = Map<String, Map<String, ReadReceipt>>();

    final flatReceipts = await store.find(storage);

    for (RecordSnapshot<String, String> record in flatReceipts) {
      final testing = await json.decode(record.value);
      final mapped = Map<String, dynamic>.from(testing);
      final Map<String, ReadReceipt> converted = mapped.map(
        (key, value) => MapEntry(key, ReadReceipt.fromJson(value)),
      );
      receipts[record.key] = converted;
    }

    return receipts;
  } catch (error) {
    printError(error);
    return null;
  }
}
