import 'dart:async';

import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/events/receipts/model.dart';

///
/// Reaction Queries - unencrypted (Cold Storage)
///
/// In storage, reactions are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension ReceiptQueries on StorageDatabase {
  Future<void> insertReceiptsBatched(List<Receipt> receipts) {
    return batch(
      (batch) => batch.insertAllOnConflictUpdate(
        this.receipts,
        receipts,
      ),
    );
  }

  ///
  /// Select Receipts (Ids)
  ///
  /// Query every message known in a room
  ///
  Future<List<Receipt>> selectReceipts(List<String> eventIds) {
    return (select(receipts)..where((tbl) => tbl.eventId.isIn(eventIds))).get();
  }
}

///
/// Save Receipts
///
///
Future<void> saveReceipts(
  Map<String, Receipt> receipts, {
  required StorageDatabase storage,
  required bool ready,
}) async {
  // TODO: the initial sync loads way too many read receipts
  if (!ready) return;

  return storage.insertReceiptsBatched(receipts.values.toList());
}

///
/// Load Receipts
///
/// Iterates through
///
Future<Map<String, Receipt>> loadReceipts(
  List<String> eventIds, {
  required StorageDatabase storage,
}) async {
  try {
    final receipts = await storage.selectReceipts(eventIds);

    return Map.fromIterable(
      receipts,
      key: (receipt) => receipt.eventId,
      value: (receipt) => receipt,
    );
  } catch (error) {
    printError(error.toString(), title: 'loadReactions');
    return {};
  }
}
