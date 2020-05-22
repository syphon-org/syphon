import 'dart:async';

import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/global/libs/matrix/errors.dart';
import 'package:Tether/global/libs/matrix/index.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/store/rooms/actions.dart';

import 'package:Tether/store/index.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetSyncing {
  final bool syncing;
  SetSyncing({this.syncing});
}

class SetSynced {
  final bool synced;
  final bool syncing;
  final String lastSince;
  SetSynced({this.synced, this.syncing, this.lastSince});
}

class SetSyncObserver {
  final Timer syncObserver;
  SetSyncObserver({this.syncObserver});
}

class ResetSync {
  ResetSync();
}

/**
 * Initial Sync - Custom Solution for /sync
 * 
 * This will only be run on log in because the matrix protocol handles
 * initial syncing terribly. It's incredibly cumbersome to load thousands of events
 * for multiple rooms all at once in order to show the user just some room names
 * and timestamps. Lazy loading isn't always supported, so it's not a solid solution
 */
ThunkAction<AppState> initialSync() {
  return (Store<AppState> store) async {
    // Start initial sync in background
    store.dispatch(fetchSync());

    // Fetch All Room Ids
    await store.dispatch(fetchRooms());
    await store.dispatch(fetchDirectRooms());
  };
}

/**
 * 
 * Fetch Sync
 * 
 * Responsible for updates based on differences from Matrix
 *  
 */
ThunkAction<AppState> fetchSync({String since, bool forceFull = false}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetSyncing(syncing: true));
      final isFullSync = since == null;
      if (isFullSync) {
        print('[fetchSync] fetching full sync');
      }

      // Matrix Sync to homeserver
      final data = await compute(MatrixApi.syncBackground, {
        'protocol': protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'fullState': forceFull || store.state.roomStore.rooms == null,
        'since': forceFull ? null : since ?? store.state.roomStore.lastSince,
      });

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.unknown_token) {
          // TODO: signin prompt needed
          print('[fetchSync] invalid token - prompt info on offline mode');
        } else {
          throw data['error'];
        }
      }

      final Map<String, dynamic> rawRooms = data['rooms']['join'];

      // Local state updates based on changes
      await store.dispatch(syncRoomState(rawRooms));

      // Update synced to indicate init sync and next batch id (lastSince)
      store.dispatch(SetSynced(
        synced: true,
        syncing: false,
        lastSince: data['next_batch'],
      ));

      // TODO: encrypt and find a way to reasonably update this
      if (isFullSync) {
        Cache.sync.put(Cache.syncKey, data);
      }

      if (!kReleaseMode && isFullSync) {
        print('[fetchSync] full sync completed');
      }
    } catch (error) {
      print('[fetchSync] error $error');
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

/**
 * Default Room Sync Observer
 * 
 * This will be run after the initial sync. Following login or signup, users
 * will just have an observer that runs every second or so to sync with the server
 * only while the app is _active_ otherwise, it will be up to a background service
 * and a notification service to trigger syncs
 */
ThunkAction<AppState> startSyncObserver() {
  return (Store<AppState> store) async {
    Timer syncObserver = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (store.state.syncStore.lastSince == null) {
        print('[Room Observer] skipping sync, needs full sync');
        return;
      }

      final lastUpdate = DateTime.fromMillisecondsSinceEpoch(
        store.state.syncStore.lastUpdate,
      );
      final retryTimeout =
          DateTime.now().difference(lastUpdate).compareTo(Duration(hours: 1));

      if (0 < retryTimeout) {
        print('[Room Observer] forced retry timeout');
        store.dispatch(fetchSync(since: store.state.syncStore.lastSince));
        return;
      }

      if (store.state.syncStore.syncing) {
        print('[Room Observer] still syncing');
        return;
      }

      print('[Room Observer] running sync');
      store.dispatch(fetchSync(since: store.state.syncStore.lastSince));
    });

    store.dispatch(SetSyncObserver(syncObserver: syncObserver));
  };
}

/**
 * Stop Sync Observer 
 * 
 * Will prevent the app from syncing with the homeserver 
 * every few seconds
 */
ThunkAction<AppState> stopSyncObserver() {
  return (Store<AppState> store) async {
    if (store.state.syncStore.syncObserver != null) {
      store.state.syncStore.syncObserver.cancel();
      store.dispatch(SetSyncObserver(syncObserver: null));
    }
  };
}

/**
 * Sync Storage Data
 * 
 * Will update the cold storage block of data
 * from the full_state /sync call
 */
ThunkAction<AppState> saveSyncStorage(
  Map roomData,
) {
  return (Store<AppState> store) async {
    // Refreshing myself on list concat in dart without spread
    // Map testing = {
    //   "1": ["a", "b", "c"]
    // };
    // Map again = {
    //   "1": ["e", "f", "g"],
    // };

    // testing.update("1", (value) => value + again["1"]);
    // print(testing);
  };
}

/**
 * Sync Storage Data
 * 
 * Will update the cold storage block of data
 * from the full_state /sync call
 */
ThunkAction<AppState> loadSync(
  Map roomData,
) {
  return (Store<AppState> store) async {};
}
