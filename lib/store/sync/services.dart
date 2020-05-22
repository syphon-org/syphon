import 'dart:async';
import 'dart:isolate';

import 'package:Tether/global/libs/hive/index.dart';
import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

/** 
 *  Save Full Sync
 * 
 *  https://github.com/hivedb/hive/issues/122
 */
FutureOr<void> saveSyncIsolate(dynamic params) async {
  print('[saveSyncIsolate] ${Isolate.current.hashCode} ${params['location']}');

  final storageLocation = params['location'];
  Hive.init(storageLocation);

  Box syncBox = await Hive.openBox(Cache.backgroundKeyUNSAFE);

  // final encryptionKey = await unlockEncryptionKey();

  // final syncBox = await Hive.openBox(
  //   Cache.syncKey,
  //   encryptionCipher: HiveAesCipher(encryptionKey),
  //   compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
  // );

  print('[saveSyncIsolate] it saves to box');

  await syncBox.put(Cache.syncKey, params['sync']);
  await syncBox.close();
}

/** 
 *  Save Full Sync
 */
FutureOr<dynamic> loadSyncIsolate(dynamic params) async {
  final int isolateId = Isolate.current.hashCode;

  print('[saveSyncIsolate] $isolateId');

  Hive.init(params['location']);
  LazyBox syncBox = await openHiveSync();

  final syncData = await syncBox.get(Cache.syncKey);
  await syncBox.close();
  return syncData;
}
