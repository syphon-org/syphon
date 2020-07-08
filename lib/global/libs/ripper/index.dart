import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/state.dart';
import 'package:syphon/store/rooms/state.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/state.dart';

class Ripper {
  static cacheStore(AppState state) async {
    try {
      debugPrint(
        '[Hive Storage] entiries ${state.mediaStore.mediaCache.length}',
      );

      FlutterIsolate.spawn(isolateTesting, 'testing');
      compute(cacheStoreMediaIsolate, state.mediaStore);
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    Cache.state.put(
      state.authStore.runtimeType.toString(),
      state.authStore,
    );

    try {
      Cache.state.put(
        state.syncStore.runtimeType.toString(),
        state.syncStore,
      );
      debugPrint('[Hive Storage] caching syncStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      Cache.stateRooms.put(
        state.roomStore.runtimeType.toString(),
        state.roomStore,
      );
      debugPrint('[Hive Storage] caching roomStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      Cache.state.put(
        state.mediaStore.runtimeType.toString(),
        state.mediaStore,
      );
      debugPrint('[Hive Storage] caching mediaStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      Cache.state.put(
        state.settingsStore.runtimeType.toString(),
        state.settingsStore,
      );
      debugPrint('[Hive Storage] caching settingsStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      Cache.state.put(
        state.cryptoStore.runtimeType.toString(),
        state.cryptoStore,
      );
      debugPrint('[Hive Storage] caching cryptoStore');
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }
  }

  static AppState loadStore() {
    AuthStore authStoreConverted = AuthStore();
    SyncStore syncStoreConverted = SyncStore();
    CryptoStore cryptoStoreConverted = CryptoStore();
    MediaStore mediaStoreConverted = MediaStore();
    RoomStore roomStoreConverted = RoomStore();
    SettingsStore settingsStoreConverted = SettingsStore();

    authStoreConverted = Cache.state.get(
      authStoreConverted.runtimeType.toString(),
      defaultValue: AuthStore(),
    );

    try {
      syncStoreConverted = Cache.state.get(
        syncStoreConverted.runtimeType.toString(),
        defaultValue: SyncStore(),
      );
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      cryptoStoreConverted = Cache.state.get(
        cryptoStoreConverted.runtimeType.toString(),
        defaultValue: CryptoStore(),
      );
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      roomStoreConverted = Cache.stateRooms.get(
        roomStoreConverted.runtimeType.toString(),
        defaultValue: RoomStore(),
      );
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      mediaStoreConverted = Cache.stateCache.get(
        mediaStoreConverted.runtimeType.toString(),
        defaultValue: MediaStore(),
      );
      debugPrint(
        '[Hive Storage] loaded ${mediaStoreConverted.mediaCache.length}',
      );
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    try {
      settingsStoreConverted = Cache.state.get(
        settingsStoreConverted.runtimeType.toString(),
        defaultValue: SettingsStore(),
      );
    } catch (error) {
      debugPrint('[Hive Storage] $error');
    }

    return AppState(
      loading: false,
      authStore: authStoreConverted,
      syncStore: syncStoreConverted,
      cryptoStore: cryptoStoreConverted,
      roomStore: roomStoreConverted,
      mediaStore: mediaStoreConverted,
      settingsStore: settingsStoreConverted,
    );
  }
}

/**
 * 
 * 
 * 
  NOTE: cannot do this unfortunately
  SettingsStoreAdapter().write(writer, state.settingsStore);

 */
void isolateTesting(String testing) async {
  debugPrint(
    '[isolateTesting] compute ${testing}',
  );

  // Init storage location
  var storageLocation;
  try {
    storageLocation = await getApplicationDocumentsDirectory();
    debugPrint(
      '[isolateTesting] compute ${storageLocation}',
    );
  } catch (error) {
    print('[isolateTesting] storage location failure - $error');
  }
}

void cacheStoreMediaIsolate(MediaStore store) async {
  debugPrint(
    '[cacheStoreMediaIsolate] compute ${store.mediaCache.length}',
  );

  // Init storage location
  var storageLocation;
  try {
    WidgetsFlutterBinding.ensureInitialized();
    storageLocation = await getApplicationDocumentsDirectory();
  } catch (error) {
    print('[cacheStoreMediaIsolate] storage location failure - $error');
  }

  // // Init hive cache + adapters
  try {
    Hive.init(storageLocation.path);
    Hive.registerAdapter(MediaStoreAdapter());
    Box stateCache = await Hive.openBox(Cache.keyStateUnsafe);
    stateCache.put(store.runtimeType.toString(), store);

    debugPrint('[Hive Storage] caching mediaStore');
  } catch (error) {
    debugPrint('[Hive Storage] $error');
  }
}
