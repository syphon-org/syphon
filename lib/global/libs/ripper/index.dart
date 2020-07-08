import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/search/state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/**
 *  
 * A Hive Manager
 * 
 * Purpose is to take serialized objects and cache them in hive
 * in a background thread 
 */
class Ripper {
  static FutureOr<void> cacheAppState(AppState state) {}
  static FutureOr<void> cacheStoreSettings(SearchStore state) {}

  static FutureOr<void> cacheStoreMedia(MediaStore mediaStore) async {
    debugPrint(
      '[cacheStoreMedia] compute ${mediaStore.mediaCache.values.length}',
    );

    // Init storage location
    var storageLocation;
    try {
      storageLocation = await getApplicationDocumentsDirectory();
    } catch (error) {
      print('[cacheStoreMedia] storage location failure - $error');
    }

    // Init hive cache + adapters
    try {
      Hive.init(storageLocation.path);
      Hive.registerAdapter(MediaStoreAdapter());
      Box stateCache = await Hive.openBox(Cache.keyStateUnsafe);
      stateCache.put(mediaStore.runtimeType.toString(), mediaStore);

      debugPrint('[Hive Storage] caching mediaStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }
  }
}
