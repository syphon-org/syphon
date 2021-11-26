import 'dart:async';
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/events/redaction/model.dart';

///
/// Save Redactions
///
/// Saves redactions to a map keyed by
/// event ids of redacted events
///
/// TODO: save redaction to messages and reactions tables
///
Future<void> saveRedactions(
  List<Redaction> redactions, {
  required Database storage,
}) async {
  try {
    final store = StoreRef<String?, String>(StorageKeys.REDACTIONS);

    return await storage.transaction((txn) async {
      for (final Redaction redaction in redactions) {
        final record = store.record(redaction.redactId);
        await record.put(txn, json.encode(redaction));
      }
    });
  } catch (error) {
    printError('[saveRedactions] $error');
    rethrow;
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
  required Database storage,
}) async {
  final store = StoreRef<String, String>(StorageKeys.REDACTIONS);

  final redactions = <String, Redaction>{};

  final redactionsData = await store.find(storage);

  for (final RecordSnapshot<String, String> record in redactionsData) {
    redactions[record.key] = Redaction.fromJson(
      json.decode(record.value),
    );
  }

  return redactions;
}
