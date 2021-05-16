import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';

Future<bool> checkMedia(
  String? mxcUri, {
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.MEDIA);

  return await store.record(mxcUri).exists(storage);
}

Future<void> saveMedia(
  String? mxcUri,
  Uint8List? data, {
  required Database storage,
}) async {
  final store = StoreRef<String?, String>(StorageKeys.MEDIA);

  return await storage.transaction((txn) async {
    final record = store.record(mxcUri);
    await record.put(txn, await compute(jsonEncode, data));
  });
}

/**
 * Load Media (Cold Storage)
 * 
 * load one set of media data based on mxc uri
 */
Future<Uint8List?> loadMedia({
  String? mxcUri,
  required Database storage,
}) async {
  try {
    final store = StoreRef<String?, String>(StorageKeys.MEDIA);

    final mediaData = await store.record(mxcUri).get(storage);

    final dataBytes = json.decode(mediaData!);

    // Convert json decoded List<int> to Uint8List
    if (dataBytes == null) {
      return null;
    }

    return Uint8List.fromList(
      (dataBytes as List).map((e) => e as int).toList(),
    );
  } catch (error) {
    printError(error.toString(), title: 'loadMedia');
    return null;
  }
}

/**
 * Load All Media (Cold Storage)
 *  
 * load all media found within media storage
 */
Future<Map<String, Uint8List>?> loadMediaAll({
  required Database storage,
}) async {
  try {
    final Map<String, Uint8List> media = {};
    final store = StoreRef<String, String>(StorageKeys.MEDIA);

    final mediaDataAll = await store.find(storage);

    for (RecordSnapshot<String, String> record in mediaDataAll) {
      final data = json.decode(record.value);

      // TODO: sometimes, a null gets saved to cold storage
      if (data != null) {
        media[record.key] = Uint8List.fromList(
          (data as List).map((e) => e as int).toList(),
        );
      }
    }

    return media;
  } catch (error) {
    printError(error.toString(), title: 'loadMediaAll');
    return null;
  }
}
