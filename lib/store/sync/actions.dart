// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetBackoff {
  final int backoff;
  SetBackoff({this.backoff});
}

class SetUnauthed {
  final bool unauthed;
  SetUnauthed({this.unauthed});
}

class SetOffline {
  final bool offline;
  SetOffline({this.offline});
}

class SetBackgrounded {
  final bool backgrounded;
  SetBackgrounded({this.backgrounded});
}

class SetSyncing {
  final bool syncing;
  SetSyncing({this.syncing});
}

class SetSynced {
  final bool synced;
  final bool syncing;
  final String lastSince;
  final int backoff;

  SetSynced({
    this.synced,
    this.syncing,
    this.lastSince,
    this.backoff,
  });
}

class SetSyncObserver {
  final Timer syncObserver;
  SetSyncObserver({this.syncObserver});
}

class ResetSync {
  ResetSync();
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
    final interval = store.state.syncStore.interval;

    Timer syncObserver = Timer.periodic(
      Duration(seconds: interval),
      (timer) async {
        if (store.state.syncStore.lastSince == null) {
          debugPrint('[Sync Observer] skipping sync, needs full sync');
          return;
        }

        final backoff = store.state.syncStore.backoff;
        final lastAttempt = DateTime.fromMillisecondsSinceEpoch(
          store.state.syncStore.lastAttempt,
        );

        if (backoff != 0) {
          final backoffs = fibonacci(backoff);
          final backoffFactor = backoffs[backoffs.length - 1];
          final backoffLimit = DateTime.now().difference(lastAttempt).compareTo(
                Duration(milliseconds: 1000 * backoffFactor),
              );

          debugPrint(
            '[Sync Observer] backoff at ${DateTime.now().difference(lastAttempt)} of $backoffFactor',
          );

          if (backoffLimit == 1) {
            debugPrint('[Sync Observer] forced retry timeout');
            await store.dispatch(fetchSync(
              since: store.state.syncStore.lastSince,
            ));
          }

          return;
        }

        if (store.state.syncStore.syncing) {
          debugPrint('[Sync Observer] still syncing');
          return;
        }

        debugPrint('[Sync Observer] running sync');
        store.dispatch(fetchSync(since: store.state.syncStore.lastSince));
      },
    );

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
 * Initial Sync - Custom Solution for /sync
 * 
 * This will only be run on log in because the matrix protocol handles
 * initial syncing terribly. It's incredibly cumbersome to load thousands of events
 * for multiple rooms all at once in order to show the user just some room names
 * and timestamps. Lazy loading isn't always supported, so it's not a solid solution
 * 
 * TODO: potentially re-enable the fetch rooms function if lazy_load fails
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
 * Set Backgrounded
 * 
 * Mark when the app has been backgrounded to visualize loading feedback
 *  
 */
ThunkAction<AppState> setBackgrounded(bool backgrounded) {
  return (Store<AppState> store) async {
    store.dispatch(SetBackgrounded(backgrounded: backgrounded));
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
      debugPrint('[fetchSync] starting sync');
      store.dispatch(SetSyncing(syncing: true));
      final isFullSync = since == null;
      var filterId;

      if (isFullSync) {
        debugPrint('[fetchSync] running full sync');
      }

      // Normal matrix /sync call to the homeserver (Threaded)
      final data = await compute(MatrixApi.syncBackground, {
        'protocol': protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'fullState': forceFull || store.state.roomStore.rooms == null,
        'since': forceFull ? null : since ?? store.state.roomStore.lastSince,
        'filter': filterId,
        'timeout': 10000
      });

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.unknown_token) {
          store.dispatch(SetUnauthed(unauthed: true));
          // TODO: signin prompt needed here
        }

        throw data['error'];
      }

      final nextBatch = data['next_batch'];
      final oneTimeKeyCount = data['device_one_time_keys_count'];
      final Map<String, dynamic> rawJoined = data['rooms']['join'];
      final Map<String, dynamic> rawInvites = data['rooms']['invite'];
      final Map<String, dynamic> rawLeft = data['rooms']['leave'];
      final Map<String, dynamic> rawToDevice = data['to_device'];
      // TODO: final Map presence = data['presence'];

      // Updates for rooms
      await store.dispatch(syncRooms(rawJoined));
      await store.dispatch(syncRooms(rawInvites));

      // Updates for device specific data (mostly room encryption)
      await store.dispatch(syncDevice(rawToDevice));

      // Update encryption one time key count
      store.dispatch(updateOneTimeKeyCounts(oneTimeKeyCount));

      // TODO: cold storage cache the full sync in encrypted file
      // if (isFullSync) {
      //   store.dispatch(saveSync(data));
      // }

      // Update synced to indicate init sync and next batch id (lastSince)
      store.dispatch(SetSynced(
        synced: true,
        syncing: false,
        lastSince: nextBatch,
      ));

      if (isFullSync) {
        debugPrint('[fetchSync] full sync completed');
      }
    } catch (error) {
      String message = '';

      try {
        // try to understand the error message
        message = (error.message as String);
      } catch (error) {
        debugPrint(error);
      }

      if (message.contains('SocketException')) {
        debugPrint('[fetchSync] IOException $error');
        store.dispatch(SetOffline(offline: true));
      }

      final backoff = store.state.syncStore.backoff;
      final nextBackoff = backoff != 0 ? backoff + 1 : 5;
      store.dispatch(SetBackoff(backoff: nextBackoff));
    } finally {
      store.dispatch(setBackgrounded(false));
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

// WARNING: ONLY FOR TESTING OUTPUT
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

// WARNING: ONLY FOR TESTING OUTPUT
Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/matrix.json');
}

// WARNING: ONLY FOR TESTING OUTPUT
Future<dynamic> readFullSyncJson() async {
  try {
    final file = await _localFile;
    String contents = await file.readAsString();
    return await jsonDecode(contents);
  } catch (error) {
    // If encountering an error, return 0.
    debugPrint('[readFullSyncJson] $error');
    return null;
  } finally {
    debugPrint('** Read State From Disk Successfully **');
  }
}
