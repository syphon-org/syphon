import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/algos.dart';
import 'package:syphon/global/connectivity.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/receipts/actions.dart';
import 'package:syphon/store/events/redaction/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/sync/parsers.dart';
import 'package:syphon/store/user/actions.dart';

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

      if (accessToken == null) {
        printInfo('[syncObserver] skipping sync, context not authenticated');
        return;
      }

      if (lastSince == null) {
        printInfo('[syncObserver] skipping sync, needs full sync');
        return;
      }

      if (syncing) {
        printInfo('[syncObserver] still syncing');
        return;
      }

      var backoff = store.state.syncStore.backoff;

      if (backoff != 0) {
        if (backoff > 5 && ConnectionService.isConnected()) {
          ConnectionService.checked = true;
          backoff = 0;
        }
      }

      if (backoff != 0) {
        final lastAttemptMillis = store.state.syncStore.lastAttempt;
        final lastAttempt = DateTime.fromMillisecondsSinceEpoch(
          lastAttemptMillis!,
        );

        final backoffs = fibonacci(backoff);
        final backoffFactor = backoffs[backoffs.length - 1];
        final backoffLimit = DateTime.now().difference(lastAttempt).compareTo(
              Duration(milliseconds: 1000 * backoffFactor),
            );

        printInfo(
          '[syncObserver] backoff at ${DateTime.now().difference(lastAttempt)} of $backoffFactor',
        );

        if (backoffLimit != 1) {
          return;
        }

        printInfo('[syncObserver] backoff timeout, trying again');
      }

      printInfo('[syncObserver] running sync');
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
ThunkAction<AppState> initialSync() {
  return (Store<AppState> store) async {
    // Start initial sync in background
    await store.dispatch(SetSyncing(syncing: true));
    await store.dispatch(fetchSync());

    final lastSince = store.state.syncStore.lastSince;

    // Fetch All Room Ids - continue showing a sync
    if (lastSince != null) {
      await store.dispatch(fetchDirectRooms());
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
      printInfo('[fetchSync] *** starting sync *** ');
      store.dispatch(SetSyncing(syncing: true));

      final lastSince = store.state.syncStore.lastSince;
      final isFullSync = forceFull || since == null;

      if (isFullSync) {
        printInfo('[fetchSync] *** full sync running *** ');
      }

      // Normal matrix /sync call to the homeserver (Threaded)
      final data = await compute(MatrixApi.syncThreaded, {
        'protocol': store.state.authStore.protocol,
        'homeserver': store.state.authStore.user.homeserver,
        'accessToken': store.state.authStore.user.accessToken,
        'fullState': isFullSync,
        'since': forceFull ? null : since ?? lastSince,
        'filter': null,
        'timeout': store.state.settingsStore.syncPollTimeout,
        'proxySettings': store.state.settingsStore.proxySettings,
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
        printInfo('[fetchSync] *** full sync completed ***');
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

///
/// Sync State Data
///
/// Helper action that will determine how to update a room
/// from data formatted like a sync request
///
ThunkAction<AppState> syncRooms(Map roomData) {
  return (Store<AppState> store) async {
    // init new store containers
    final rooms = store.state.roomStore.rooms;
    final user = store.state.authStore.user;
    final synced = store.state.syncStore.synced;
    final lastSince = store.state.syncStore.lastSince;

    await Future.forEach(roomData.keys, (id) async {
      try {
        final String roomId = id?.toString() ?? '';
        final Map json = roomData[roomId] ?? {};

        if (json.isEmpty) return;

        final roomOld = rooms.containsKey(roomId) ? rooms[roomId]! : Room(id: roomId);
        final messagesOld = store.state.eventStore.messages[roomId] ?? [];

        final sync = await compute(parseSync, {
          'json': json,
          'room': roomOld,
          'currentUser': user,
          'lastSince': lastSince,
          'existingMessages': messagesOld.map((m) => m.id ?? '').toList(),
        });

        // overwrite room with updated one from sync
        final roomSynced = sync.room;

        printInfo(
          // ignore: prefer_interpolation_to_compose_strings
          '[syncRooms] ${roomSynced.name} ' +
              'full_synced: $synced ' +
              'limited: ${roomSynced.limited} ' +
              'total new messages: ${sync.messages.length} ' +
              'roomPrevBatch: ${roomSynced.prevBatch}',
        );

        // update various message mutations and meta data
        await store.dispatch(setUsers(sync.users));
        await store.dispatch(setReceipts(room: roomSynced, receipts: sync.readReceipts));
        await store.dispatch(addReactions(reactions: sync.reactions));

        // redact events (reactions and messages) through cache and cold storage
        await store.dispatch(redactEvents(room: roomSynced, redactions: sync.redactions));

        // handles editing newly fetched messages
        final messages = await store.dispatch(mutateMessages(
          messages: sync.messages,
          existing: messagesOld,
        )) as List<Message>;

        // update encrypted messages (updating before normal messages prevents flicker)
        if (roomSynced.encryptionEnabled) {
          final decryptedOld = store.state.eventStore.messagesDecrypted[roomId];

          final decrypted = await store.dispatch(decryptMessages(
            roomSynced,
            messages,
          )) as List<Message>;

          // handles editing newly fetched decrypted messages
          final decryptedMutated = await store.dispatch(mutateMessages(
            messages: decrypted,
            existing: decryptedOld,
          )) as List<Message>;

          await store.dispatch(addMessagesDecrypted(
            roomId: roomSynced.id,
            messages: decryptedMutated,
          ));
        }

        // save normal or encrypted messages
        await store.dispatch(addMessages(
          roomId: roomSynced.id,
          messages: messages,
          clear: sync.override ?? false,
        ));

        // update room
        store.dispatch(SetRoom(room: roomSynced));

        // fetch avatar if a uri was found
        if (roomSynced.avatarUri != null) {
          store.dispatch(fetchMedia(
            mxcUri: roomSynced.avatarUri,
            thumbnail: true,
          ));
        }

        // fetch previous messages since last /sync (a messages gap)
        // room will be marked limited to indicate this
        if (roomSynced.limited) {
          printWarning(
            '[syncRooms] ${roomSynced.name} LIMITED TRUE - Fetching more messages',
          );

          store.dispatch(fetchMessageEvents(
            room: roomSynced,
            from: roomSynced.prevBatch,
            override: true,
          ));
        }
        // TODO: this should happen immediately and backfill should happen in background
        // a recursive sync for the messages gap has now finished
        //  else if (!roomSynced.limited && roomOld.limited) {
        //   final messagesSorted = latestMessages(messagesOld);

        //   // wipe all but the latest 25 messages from the cache
        //   await store.dispatch(addMessages(
        //     room: roomSynced,
        //     messages:
        //         messagesSorted.sublist(0, messagesSorted.length > 25 ? 25 : messagesSorted.length),
        //     clear: true,
        //   ));
        // }
      } catch (error) {
        final String roomId = id?.toString() ?? '';
        printError('[syncRoom] error $roomId ${error.toString()}');

        // prevents against recursive backfill from bombing attempts at fetching messages
        final roomExisting = rooms.containsKey(roomId) ? rooms[roomId]! : Room(id: roomId);
        store.dispatch(SetRoom(room: roomExisting.copyWith(limited: false)));
      }
    });
  };
}

// TODO: a non-recursive backfill of "limited" room timelines
ThunkAction<AppState> syncBackfill(
  String? roomId, {
  List<String> previousIds = const [],
}) {
  return (Store<AppState> store) async {
    if (previousIds.isEmpty) {
      return;
    }
  };
}
