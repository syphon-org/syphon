import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/global/libraries/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Reaction Queries - unencrypted (Cold Storage)
///
/// In storage, reactions are indexed by eventId
/// In redux, they're indexed by RoomID and placed in a list
///
extension ReceiptQueries on StorageDatabase {
  Future<void> insertReceiptsBatched(List<Receipt> receipts) {
    // HACK: temporary to account for sqlite versions without UPSERT
    if (Platform.isLinux) {
      return batch(
        (batch) => batch.insertAll(
          this.receipts,
          receipts,
          mode: InsertMode.insertOrReplace,
        ),
      );
    }
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
    log.error(error.toString(), title: 'loadReactions');
    return {};
  }
}
