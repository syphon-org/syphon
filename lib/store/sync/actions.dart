import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/algos.dart';
import 'package:syphon/global/connectivity.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';

class SetBackoff {
  final int? backoff;
  SetBackoff({this.backoff});
}

class SetUnauthed {
  final bool? unauthed;
  SetUnauthed({this.unauthed});
}

class SetOffline {
  final bool? offline;
  SetOffline({this.offline});
}

class SetBackgrounded {
  final bool? backgrounded;
  SetBackgrounded({this.backgrounded});
}

class SetSyncing {
  final bool? syncing;
  SetSyncing({this.syncing});
}

class SetSynced {
  final bool? synced;
  final bool? syncing;
  final String? lastSince;
  final int? backoff;

  SetSynced({
    this.synced,
    this.syncing,
    this.lastSince,
    this.backoff,
  });
}

class SetSyncObserver {
  final Timer? syncObserver;
  SetSyncObserver({this.syncObserver});
}

class ResetSync {}

///
/// Default Sync Observer
///
/// This will be run after the initial sync. Following login or signup, users
/// will just have an observer that runs every second or so to sync with the server
/// only while the app is _active_ otherwise, it will be up to a background service
/// and a notification service to trigger syncs
///
ThunkAction<AppState> startSyncObserver() {
  return (Store<AppState> store) async {
    final interval = store.state.settingsStore.syncInterval;
    final syncObserver = store.state.syncStore.syncObserver;

    onSync(timer) async {
      final accessToken = store.state.authStore.user.accessToken;
      final lastSince = store.state.syncStore.lastSince;
      final syncing = store.state.syncStore.syncing;

      final currentStatus = ConnectionService.currentStatus;

      if (accessToken == null) {
        debugPrint('[syncObserver] skipping sync, context not authenticated');
        return;
      }

      if (lastSince == null) {
        debugPrint('[syncObserver] skipping sync, needs full sync');
        return;
      }

      if (syncing) {
        debugPrint('[syncObserver] still syncing');
        return;
      }

      var backoff = store.state.syncStore.backoff;
      final lastAttemptMillis = store.state.syncStore.lastAttempt;
      final lastAttempt = DateTime.fromMillisecondsSinceEpoch(
        lastAttemptMillis!,
      );

      if (ConnectionService.isConnected() && backoff > 5) {
        ConnectionService.checked = true;
        backoff = 0;
      }

      if (backoff != 0) {
        final backoffs = fibonacci(backoff);
        final backoffFactor = backoffs[backoffs.length - 1];
        final backoffLimit = DateTime.now().difference(lastAttempt).compareTo(
              Duration(milliseconds: 1000 * backoffFactor),
            );

        debugPrint(
          '[syncObserver] backoff at ${DateTime.now().difference(lastAttempt)} of $backoffFactor',
        );

        if (backoffLimit != 1) {
          return;
        }

        debugPrint('[syncObserver] backoff timeout, trying again');
      }

      debugPrint('[syncObserver] running sync');
      store.dispatch(fetchSync(since: lastSince));
    }

    if (syncObserver == null || !syncObserver.isActive) {
      store.dispatch(SetSyncObserver(
        syncObserver: Timer.periodic(Duration(milliseconds: interval), onSync),
      ));
    }
  };
}

/// Stop Sync Observer
///
/// Will prevent the app from syncing with the homeserver
/// every few seconds
ThunkAction<AppState> stopSyncObserver() {
  return (Store<AppState> store) {
    final syncObserver = store.state.syncStore.syncObserver;
    if (syncObserver != null && syncObserver.isActive) {
      syncObserver.cancel();
    }
  };
}

/// Initial Sync - Custom Solution for /sync
///
/// This will only be run on log in because the matrix protocol handles
/// initial syncing terribly. It's incredibly cumbersome to load thousands of events
/// for multiple rooms all at once in order to show the user just some room names
/// and timestamps. Lazy loading isn't always supported, so it's not a solid solution
///
/// TODO: potentially re-enable the fetch rooms function if lazy_load fails
ThunkAction<AppState> initialSync() {
  return (Store<AppState> store) async {
    // Start initial sync in background
    await store.dispatch(SetSyncing(syncing: true));
    await store.dispatch(fetchSync());

    final lastSince = store.state.syncStore.lastSince;

    // Fetch All Room Ids - continue showing a sync
    if (lastSince != null) {
      await store.dispatch(fetchDirectRooms());
      await store.dispatch(fetchRooms());
    }

    await store.dispatch(SetSyncing(syncing: false));
  };
}

///
/// Set Backgrounded
///
/// Mark when the app has been backgrounded to visualize loading feedback
///
ThunkAction<AppState> setBackgrounded(bool backgrounded) {
  return (Store<AppState> store) async {
    store.dispatch(SetBackgrounded(backgrounded: backgrounded));
  };
}

///
/// Fetch Sync
///
/// Responsible for updates based on differences from Matrix
///
ThunkAction<AppState> fetchSync({String? since, bool forceFull = false}) {
  return (Store<AppState> store) async {
    try {
      debugPrint('[fetchSync] *** starting sync *** ');
      store.dispatch(SetSyncing(syncing: true));

      final lastSince = store.state.syncStore.lastSince;
      final isFullSync = forceFull || since == null || store.state.roomStore.rooms.isEmpty;

      if (isFullSync) {
        debugPrint('[fetchSync] *** full sync running *** ');
      }

      // Normal matrix /sync call to the homeserver (Threaded)
      final data = await compute(MatrixApi.syncBackground, {
        'protocol': store.state.authStore.protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'fullState': isFullSync,
        'since': forceFull ? null : since ?? lastSince,
        'filter': null,
        'timeout': store.state.settingsStore.syncPollTimeout
      });

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.unknown_token) {
          store.dispatch(SetUnauthed(unauthed: true));
          // TODO: signin prompt needed here
        }

        throw data['error'];
      }

      // final Map presence = data['presence'];

      final String nextBatch = data['next_batch'];
      final Map<String, dynamic> roomJson = data['rooms'] ?? {};
      final Map<String, dynamic> toDeviceJson = data['to_device'] ?? {};
      final Map<String, dynamic> oneTimeKeyCount = data['device_one_time_keys_count'] ?? {};

      if (roomJson.isNotEmpty) {
        final Map<String, dynamic> joinedJson = roomJson['join'] ?? {};
        final Map<String, dynamic> invitesJson = roomJson['invite'] ?? {};
        // final Map<String, dynamic> rawLeft = data['rooms']['leave'];

        // Updates for rooms
        if (joinedJson.isNotEmpty) {
          await store.dispatch(syncRooms(joinedJson));
        }
        if (invitesJson.isNotEmpty) {
          await store.dispatch(syncRooms(invitesJson));
        }
      }
      if (toDeviceJson.isNotEmpty) {
        // Updates for device specific data (mostly room encryption)
        await store.dispatch(syncDevice(toDeviceJson));
      }

      // Update encryption one time key count
      store.dispatch(updateOneTimeKeyCounts(
        Map<String, int>.from(oneTimeKeyCount),
      ));

      // Update synced to indicate init sync and next batch id (lastSince)
      store.dispatch(SetSynced(
        synced: true,
        syncing: false,
        lastSince: nextBatch,
      ));

      if (isFullSync) {
        debugPrint('[fetchSync] *** full sync completed ***');
      }
    } catch (error) {
      store.dispatch(SetOffline(offline: true));
      printError('[fetchSync] error ${error.toString()}');

      final backoff = store.state.syncStore.backoff;
      final nextBackoff = backoff != 0 ? backoff + 1 : 5;
      store.dispatch(SetBackoff(backoff: nextBackoff));
      store.dispatch(SetSyncing(syncing: false));
    } finally {
      if (store.state.syncStore.backgrounded) {
        store.dispatch(setBackgrounded(false));
      }
    }
  };
}
