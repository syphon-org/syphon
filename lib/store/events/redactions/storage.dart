import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/redactions/model.dart';

///
/// Save Redactions
///
/// Saves redactions to a map keyed by
/// event ids of redacted events
///
Future<void> saveRedactions(
  List<Redaction> redactions, {
  Database storage,
}) async {
  try {
    final store = StoreRef<String, String>(StorageKeys.REDACTIONS);

    return await storage.transaction((txn) async {
      for (Redaction redaction in redactions) {
        final record = store.record(redaction.redactId);
        await record.put(txn, json.encode(redaction));
      }
    });
  } catch (error) {
    printError('[saveRedactions] $error');
    throw error;
  }
}

///
/// Load Redactions
///
/// Load all the redactions from storage
/// filtering should occur shortly after in
/// another parser/filter/selector
///
Future<Map<String, Redaction>> loadRedactions({
  Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.REDACTIONS);

  final redactions = Map<String, Redaction>();

  final redactionsData = await store.find(storage);

  for (RecordSnapshot<String, String> record in redactionsData) {
    redactions[record.key] = Redaction.fromJson(
      json.decode(record.value),
    );
  }

  return redactions;
}
