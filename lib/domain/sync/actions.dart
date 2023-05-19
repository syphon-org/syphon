import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/domain/crypto/events/actions.dart';
import 'package:syphon/domain/crypto/keys/actions.dart';
import 'package:syphon/domain/events/actions.dart';
import 'package:syphon/domain/events/messages/actions.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/reactions/actions.dart';
import 'package:syphon/domain/events/receipts/actions.dart';
import 'package:syphon/domain/events/redaction/actions.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/media/actions.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/sync/parsers/parsers.dart';
import 'package:syphon/domain/sync/service/storage.dart';
import 'package:syphon/domain/user/actions.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/connectivity.dart';
import 'package:syphon/global/libraries/matrix/errors.dart';
import 'package:syphon/global/libraries/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

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
  final int? backoff;
  final bool? synced;
  final bool? syncing;
  final String? lastSince;

  SetSynced({
    this.synced,
    this.syncing,
    this.backoff,
    this.lastSince,
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
        console.info('[syncObserver] skipping sync, context not authenticated');
        return;
      }

      if (lastSince == null) {
        console.info('[syncObserver] skipping sync, needs full sync');
        return;
      }

      if (syncing) {
        console.info('[syncObserver] still syncing');
        return;
      }

      var backoff = store.state.syncStore.backoff;

      if (backoff != 0) {
        final lastStatus = ConnectionService.lastStatus;
        final currentStatus = ConnectionService.currentStatus;
        final hasChanged = lastStatus != currentStatus;

        if (backoff > 5 && hasChanged && ConnectionService.isConnected()) {
          backoff = 0;
        }

        ConnectionService.lastStatus = ConnectionService.currentStatus;
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

        console.info(
          '[syncObserver] backoff at ${DateTime.now().difference(lastAttempt)} of $backoffFactor',
        );

        if (backoffLimit != 1) {
          return;
        }

        console.info('[syncObserver] backoff timeout, trying again');
      }

      console.info('[syncObserver] running sync');
      store.dispatch(fetchSync(since: lastSince));
    }

    if (syncObserver == null || !syncObserver.isActive) {
      store.dispatch(
        SetSyncObserver(
          syncObserver: Timer.periodic(Duration(milliseconds: interval), onSync),
        ),
      );
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
    await store.dispatch(fetchDirectRooms());
    await store.dispatch(SetSyncing(syncing: false));
  };
}

///
/// Set Backgrounded
///
/// Mark when the app has been backgrounded to visualize loading feedback
///
ThunkAction<AppState> setBackgrounded({bool backgrounded = false}) {
  return (Store<AppState> store) async {
    store.dispatch(SetBackgrounded(backgrounded: backgrounded));
  };
}

///
/// Updaet Last Since
///
/// Update the latest known lastSince for the background thread
/// to not notify for messages read in the app
///
ThunkAction<AppState> updateLatestLastSince() {
  return (Store<AppState> store) async {
    final lastSince = store.state.syncStore.lastSince;

    if (lastSince != null) {
      console.info('[updateLatestLastSince] updating $lastSince');
      await saveLastSince(lastSince: lastSince);
    }
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
      console.info('[fetchSync] *** starting sync *** ');
      store.dispatch(SetSyncing(syncing: true));

      final lastSince = store.state.syncStore.lastSince;
      final isFullSync = forceFull || since == null;

      if (isFullSync) {
        console.info('[fetchSync] *** full sync running *** ');
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

      final String nextBatch = data['next_batch'];
      final Map<String, dynamic> roomJson = data['rooms'] ?? {};
      final Map<String, dynamic> toDeviceJson = data['to_device'] ?? {};
      final Map<String, dynamic> oneTimeKeyCount = data['device_one_time_keys_count'] ?? {};

      // Updates for device specific data (mostly room encryption)
      if (toDeviceJson.isNotEmpty) {
        await store.dispatch(syncDevice(toDeviceJson));
      }

      // Parse and save room / message updates
      if (roomJson.isNotEmpty) {
        final Map<String, dynamic> joinedJson = roomJson['join'] ?? {};
        final Map<String, dynamic> invitesJson = roomJson['invite'] ?? {};
        final Map<String, dynamic> leavesJson = roomJson['leave'] ?? {};

        // Updates for rooms
        if (joinedJson.isNotEmpty) {
          await store.dispatch(syncRooms(joinedJson));
        }
        if (invitesJson.isNotEmpty) {
          await store.dispatch(syncRooms(invitesJson));
        }
        if (leavesJson.isNotEmpty) {
          await store.dispatch(syncRooms(leavesJson));
        }
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
        console.info('[fetchSync] *** full sync completed ***');
      }
    } catch (error) {
      console.error('[fetchSync] $error');

      final backoff = store.state.syncStore.backoff;
      final nextBackoff = backoff != 0 ? backoff + 1 : 5;

      store.dispatch(SetOffline(offline: true));
      store.dispatch(SetBackoff(backoff: nextBackoff));
      store.dispatch(SetSyncing(syncing: false));
    } finally {
      if (store.state.syncStore.backgrounded) {
        store.dispatch(setBackgrounded(backgrounded: false));
      }
    }
  };
}

ThunkAction<AppState> syncRoom(String id, Map<String, dynamic> json) {
  return (Store<AppState> store) async {
    // init new store containers
    final user = store.state.authStore.user;
    final rooms = store.state.roomStore.rooms;
    final synced = store.state.syncStore.synced;
    final lastSince = store.state.syncStore.lastSince;

    try {
      final currentRoom = rooms.containsKey(id) ? rooms[id]! : Room(id: id);
      final currentMessages = store.state.eventStore.messages[id] ?? [];

      final sync = await parseSyncThreaded(
        json: json,
        user: user,
        room: currentRoom,
        lastSince: lastSince,
        currentMessageIds: currentMessages.map((m) => m.id ?? '').toList(),
      );

      if (sync.details.leave ?? false) {
        return store.dispatch(RemoveRoom(roomId: id));
      }

      // updated room and events from sync
      final room = sync.room;
      final events = sync.events;

      if (DEBUG_MODE && DEBUG_PAYLOADS_MODE) {
        console.jsonDebug({
          'from': '[syncRooms]',
          'room': room.name,
          'synced': synced,
          'limited': room.limited,
          'lastBatch': room.lastBatch,
          'prevBatch': room.prevBatch,
        });
      }

      // update various message mutations and meta data
      await store.dispatch(setUsers(sync.users));
      await store.dispatch(setReceipts(room: room, receipts: sync.readReceipts));
      await store.dispatch(addReactions(reactions: events.reactions));

      // redact events (reactions and messages) through cache and cold storage
      await store.dispatch(redactEvents(room: room, redactions: events.redactions));

      // handles editing newly fetched messages
      final messages = await store.dispatch(
        mutateMessages(
          messages: events.messages,
          existing: currentMessages,
        ),
      ) as List<Message>;

      // update encrypted messages (updating before normal messages prevents flicker)
      if (room.encryptionEnabled) {
        final decryptedOld = store.state.eventStore.messagesDecrypted[id];

        final decrypted = await store.dispatch(
          decryptMessages(
            room,
            messages,
          ),
        ) as List<Message>;

        // handles editing newly fetched decrypted messages
        final decryptedMutated = await store.dispatch(
          mutateMessages(
            messages: decrypted,
            existing: decryptedOld,
          ),
        ) as List<Message>;

        await store.dispatch(
          addMessagesDecrypted(
            roomId: room.id,
            messages: decryptedMutated,
          ),
        );
      }

      // save normal or encrypted messages
      await store.dispatch(
        addMessages(
          roomId: room.id,
          messages: messages,
          clear: sync.details.overwrite ?? false,
        ),
      );

      if (DEBUG_MODE && DEBUG_PAYLOADS_MODE) {
        console.jsonDebug({
          'room': room,
        });
      }

      // update room
      store.dispatch(SetRoom(room: room));

      // fetch avatar if a uri was found
      if (room.avatarUri != null) {
        store.dispatch(
          fetchMedia(
            mxcUri: room.avatarUri,
            thumbnail: true,
          ),
        );
      }

      // fetch previous messages since last /sync (a messages gap)
      // room will be marked limited to indicate this
      // TODO: a backfill should happen in background when processing is available
      if (room.limited && synced) {
        console.warn(
          '[syncRooms] ${room.name} LIMITED TRUE - Fetching more messages',
        );

        store.dispatch(fetchMessageEvents(
          room: room,
          from: room.prevBatch,
          overwrite: messages.isNotEmpty,
        ));
      }
    } catch (error) {
      console.error('[syncRoom] $id $error');

      // prevents against recursive backfill from bombing attempts at fetching messages
      final roomExisting = rooms.containsKey(id) ? rooms[id]! : Room(id: id);
      store.dispatch(SetRoom(room: roomExisting.copyWith(limited: false)));
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
    await Future.forEach(roomData.keys, (id) async {
      final String roomId = id?.toString() ?? '';
      final Map<String, dynamic> json = roomData[roomId] ?? {};
      if (json.isEmpty) return;

      await store.dispatch(syncRoom(roomId, json));
    });
  };
}
