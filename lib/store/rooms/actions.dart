// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/store/rooms/selectors.dart' as roomSelectors;
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/rooms/events/actions.dart';
import 'package:syphon/store/rooms/events/selectors.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/store/user/selectors.dart';
import 'events/model.dart';
import 'room/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetSending {
  final bool sending;
  final Room room;
  SetSending({this.sending, this.room});
}

class SetRooms {
  final List<Room> rooms;
  SetRooms({this.rooms});
}

class SetRoom {
  final Room room;
  SetRoom({this.room});
}

// Atomically Update specific room attributes
class UpdateRoom {
  final String id; // room id
  final Message draft;
  final bool syncing;

  UpdateRoom({
    this.id,
    this.draft,
    this.syncing,
  });
}

class RemoveRoom {
  final Room room;
  RemoveRoom({this.room});
}

class ResetRooms {
  ResetRooms();
}

/**
 * tempId for messages that have attempted sending but not finished
 */
class SaveOutboxMessage {
  final String id; // TODO: room id
  final String tempId;
  final Message pendingMessage;

  SaveOutboxMessage({
    this.id,
    this.tempId,
    this.pendingMessage,
  });
}

class DeleteOutboxMessage {
  final Message message; // room id

  DeleteOutboxMessage({
    this.message,
  });
}

class AddArchive {
  final String roomId;

  AddArchive({
    this.roomId,
  });
}

/**
 * Sync State Data
 * 
 * Helper action that will determine how to update a room
 * from data formatted like a sync request
 */
ThunkAction<AppState> syncRooms(Map roomData) {
  return (Store<AppState> store) async {
    // init new store containers
    final rooms = store.state.roomStore.rooms ?? Map<String, Room>();
    final user = store.state.authStore.user;
    final lastSince = store.state.syncStore.lastSince;

    // syncing null data happens sometimes?
    if (roomData == null) {
      return;
    }

    // update those that exist or add a new room
    return await Future.forEach(roomData.keys, (id) async {
      final json = roomData[id];
      // use pre-existing values where available
      Room room = rooms.containsKey(id) ? rooms[id] : Room(id: id);

      // First past to decrypt encrypted events
      if (room.encryptionEnabled) {
        final List<dynamic> timelineEvents = json['timeline']['events'];

        // map through each event and decrypt if possible
        final decryptTimelineActions = timelineEvents.map((event) async {
          final eventType = event['type'];
          switch (eventType) {
            case EventTypes.encrypted:
              return await store.dispatch(
                decryptMessageEvent(roomId: room.id, event: event),
              );
            default:
              return event;
          }
        });

        // add the decrypted events back to the
        final decryptedTimelineEvents = await Future.wait(
          decryptTimelineActions,
        );

        // reassign the mapped decrypted evets to the json timeline
        json['timeline']['events'] = decryptedTimelineEvents;
      }

      // Filter through parsers
      room = room.fromSync(
        json: json,
        currentUser: user,
        lastSince: lastSince,
      );

      // fetch avatar if a uri was found
      if (room.avatarUri != null) {
        store.dispatch(fetchThumbnail(
          mxcUri: room.avatarUri,
        ));
      }

      // Offload and save user map to cache
      await store.dispatch(syncUsers(room.users));

      // and is not already at the end of the last known batch
      // the end would be room.prevHash == room.lastHash
      // fetch previous messages since last /sync (a gap)
      // determined by the fromSync function of room
      final roomUpdated = store.state.roomStore.rooms[room.id];
      if (roomUpdated != null && room.limited) {
        store.dispatch(fetchMessageEvents(
          room: room,
          from: room.prevHash,
        ));
      }

      // update room
      store.dispatch(SetRoom(room: room));
    });
  };
}

/**
 *  
 * Fetch Rooms (w/o /sync)
 * 
 * Takes a negligible amount of time
 *  
 */
ThunkAction<AppState> fetchRooms() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchRoomIds(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Convert joined_rooms to Room objects
      final List<dynamic> joinedRoomsRaw = data['joined_rooms'];
      final joinedRooms = joinedRoomsRaw.map((id) => Room(id: id)).toList();
      final fullJoinedRooms = joinedRooms.map((room) async {
        try {
          final stateEvents = await MatrixApi.fetchStateEvents(
            protocol: protocol,
            homeserver: store.state.authStore.user.homeserver,
            accessToken: store.state.authStore.user.accessToken,
            roomId: room.id,
          );

          if (!(stateEvents is List) && stateEvents['errcode'] != null) {
            throw stateEvents['error'];
          }

          final messageEvents = await compute(
            MatrixApi.fetchMessageEventsMapped,
            {
              "protocol": protocol,
              "homeserver": store.state.authStore.user.homeserver,
              "accessToken": store.state.authStore.user.accessToken,
              "roomId": room.id,
              "limit": 20,
            },
          );

          await store.dispatch(syncRooms({
            '${room.id}': {
              'state': {
                'events': stateEvents,
              },
              'timeline': {
                'events': messageEvents['chunk'],
              }
            },
          }));
        } catch (error) {
          debugPrint('[fetchRooms] ${room.id} $error');
        } finally {
          store.dispatch(UpdateRoom(id: room.id, syncing: false));
        }
      });

      await Future.wait(fullJoinedRooms);
    } catch (error) {
      // WARNING: Silent error, throws error if they have no direct message
      debugPrint('[fetchRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Fetch Direct Rooms
 * 
 * Fetches both state and message of direct rooms
 * found from account_data of current authed user
 * 
 * Have to account for multiple direct rooms with one user
 * @riot-bot:matrix.org: [!ajJxpUAIJjYYTzvsHo:matrix.org, !124:matrix.org]
 */
ThunkAction<AppState> fetchDirectRooms() {
  return (Store<AppState> store) async {
    try {
      final data = await MatrixApi.fetchDirectRoomIds(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Mark specified rooms as direct chats
      final directRoomMap = data as Map<String, dynamic>;
      final List<Map> directRoomList = [];

      // Parse room map to allow for pulling by roomId (keeping userId)
      directRoomMap.forEach((userId, roomIds) {
        roomIds.forEach((roomId) {
          directRoomList.add({userId: roomId});
        });
      });

      // Fetch room state and messages by userId/roomId
      final directRoomData = directRoomList.map((directRoom) async {
        final userId = directRoom.keys.elementAt(0);
        final roomId = directRoom.values.elementAt(0);
        try {
          final stateEvents = await MatrixApi.fetchStateEvents(
            protocol: protocol,
            homeserver: store.state.authStore.user.homeserver,
            accessToken: store.state.authStore.user.accessToken,
            roomId: roomId,
          );

          if (!(stateEvents is List) && stateEvents['errcode'] != null) {
            throw stateEvents['error'];
          }

          final messageEvents = await compute(
            MatrixApi.fetchMessageEventsMapped,
            {
              "protocol": protocol,
              "homeserver": store.state.authStore.user.homeserver,
              "accessToken": store.state.authStore.user.accessToken,
              "roomId": roomId,
              "limit": 20,
            },
          );

          if (messageEvents['errcode'] != null) {
            throw messageEvents['error'];
          }

          // Format response like /sync request
          // Hacked together to provide isDirect data
          await store.dispatch(syncRooms({
            '$roomId': {
              'state': {
                'events': stateEvents,
              },
              'timeline': {
                'events': messageEvents['chunk'],
                'prev_batch': messageEvents['from'],
              },
              'account_data': {
                'events': [
                  {
                    "type": 'm.direct',
                    'content': {
                      '$userId',
                    }
                  }
                ],
              }
            },
          }));
        } catch (error) {
          debugPrint('[fetchDirectRooms] $error');
        }
      });

      // Wait for all room data to be pulled
      await Future.wait(directRoomData);
    } catch (error) {
      debugPrint('[fetchDirectRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Create Room 
 * 
 * stop / start the /sync session for this to run,
 * otherwise it will appear like the room does
 * not exist for the seconds between the response from
 * matrix and caching in the app
 */
ThunkAction<AppState> createRoom({
  String name,
  String alias,
  String topic,
  File avatarFile,
  String avatarUri,
  List<User> invites,
  bool isDirect = false,
  bool encryption = false, // TODO: defaults without group E2EE for now
  String preset = RoomPresets.private,
}) {
  return (Store<AppState> store) async {
    Room room;
    try {
      store.dispatch(SetLoading(loading: true));
      await store.dispatch(stopSyncObserver());

      final inviteIds = invites.map((user) => user.userId).toList();

      final data = await MatrixApi.createRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        name: name,
        topic: topic,
        alias: alias,
        invites: inviteIds,
        isDirect: isDirect,
        chatTypePreset: preset,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Create a room object with a new room id
      room = Room(id: data['room_id']);

      // Add invites to the user list beforehand
      final userInviteMap = Map<String, User>.fromIterable(
        invites,
        key: (user) => user.userId,
        value: (user) => user,
      );

      room = room.copyWith(users: userInviteMap);

      printJson(userInviteMap);

      if (avatarFile != null) {
        await store.dispatch(
          updateRoomAvatar(roomId: room.id, localFile: avatarFile),
        );
      }

      if (isDirect) {
        final directUser = invites[0];
        room = room.copyWith(
          direct: true,
          users: {directUser.userId: directUser},
        );

        await store.dispatch(toggleDirectRoom(room: room, enabled: true));
      }

      // direct chats are encrypted by default
      // group e2ee is not done yet
      if (encryption || isDirect) {
        await store.dispatch(toggleRoomEncryption(room: room));
      }

      await store.dispatch(SetRoom(room: room));

      return room.id;
    } catch (error) {
      store.dispatch(
        addAlert(
            message: error.toString(),
            error: error,
            origin: 'createRoom|$preset'),
      );
      return room != null ? room.id : null;
    } finally {
      await store.dispatch(startSyncObserver());
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Update Room
 * 
 * stop / start the /sync session for this to run,
 * otherwise it will appear like the room does
 * not exist for the seconds between the response from
 * matrix and caching in the app
 */
ThunkAction<AppState> updateRoom({
  String name,
  String alias,
  String topic,
  File avatarFile,
  String avatarUri,
  List<User> invites,
  bool isDirect = false,
  String preset = RoomPresets.private,
}) {
  return (Store<AppState> store) async {
    try {} catch (error) {
      debugPrint('[updateRoom] $error');
      return null;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * 
 * Mark Room Read (Locally Only)
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */
ThunkAction<AppState> markRoomRead({String roomId}) {
  return (Store<AppState> store) async {
    try {
      final room = store.state.roomStore.rooms[roomId];
      if (room == null) {
        throw 'Room not found';
      }

      // mark read locally only
      if (!store.state.settingsStore.readReceipts) {
        await store.dispatch(SetRoom(
          room: room.copyWith(lastRead: DateTime.now().millisecondsSinceEpoch),
        ));
      }

      // send read receipt remotely to mark locally on /sync
      if (store.state.settingsStore.readReceipts) {
        final messagesSorted = latestMessages(
          roomSelectors.room(id: roomId, state: store.state).messages,
        );

        if (messagesSorted.isNotEmpty) {
          store.dispatch(sendReadReceipts(
            room: Room(id: roomId),
            message: messagesSorted.elementAt(0),
          ));
        }
      }
    } catch (error) {
      store.dispatch(addAlert(
        message: 'Failed to mark room as read',
        error: error,
        origin: 'markRoomRead',
      ));
    }
  };
}

/**
 * 
 * Mark Room Read (Locally Only)
 * 
 * Send Fully Read or just Read receipts bundled into 
 * one http call
 */
ThunkAction<AppState> markRoomsReadAll() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final rooms = store.state.roomStore.roomList;

      rooms.forEach((room) {
        store.dispatch(markRoomRead(roomId: room.id));
      });
    } catch (error) {
      store.dispatch(addAlert(
        message: 'Failed to mark all room as read',
        error: error,
        origin: 'markRoomRead',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Toggle Direct Room
 * 
 * NOTE: https://github.com/matrix-org/matrix-doc/issues/1519
 * 
 * Fetch the direct rooms list and recalculate it without the
 * given alias
 */
ThunkAction<AppState> toggleDirectRoom({Room room, bool enabled}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // Pull remote direct room data
      final data = await MatrixApi.fetchDirectRoomIds(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Find the other user in the direct room
      final currentUser = store.state.authStore.user;
      final roomUsers = roomUsersSelector(room, store.state.userStore.users);
      final otherUser = roomUsers.values.firstWhere(
        (user) => user.userId != currentUser.userId,
      );

      if (otherUser == null) {
        throw 'Cannot toggle room to direct without other users';
      }

      // Pull the direct room for that specific user
      Map directRoomUsers = data as Map<String, dynamic>;
      final usersDirectRooms = directRoomUsers[otherUser.userId] ?? [];

      if (usersDirectRooms.isEmpty && enabled) {
        directRoomUsers[otherUser.userId] = [room.id];
      }

      // Toggle the direct room data based on user actions
      directRoomUsers = directRoomUsers.map((userId, rooms) {
        List<dynamic> updatedRooms = List.from(rooms ?? []);

        if (userId != otherUser.userId) {
          return MapEntry(userId, updatedRooms);
        }

        if (enabled) {
          updatedRooms.add(room.id);
        } else {
          updatedRooms.removeWhere((roomId) => roomId == room.id);
        }

        return MapEntry(userId, updatedRooms);
      });

      // Filter out empty list entries for a user
      directRoomUsers.removeWhere((key, value) {
        final roomIds = value ?? [];
        return roomIds.isEmpty;
      });

      final saveData = await MatrixApi.saveAccountData(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        userId: store.state.authStore.user.userId,
        type: AccountDataTypes.direct,
        accountData: directRoomUsers,
      );

      if (saveData['errcode'] != null) {
        throw saveData['error'];
      }

      await store.dispatch(SetRoom(room: room.copyWith(direct: enabled)));
      await store.dispatch(fetchDirectRooms());
    } catch (error) {
      debugPrint('[toggleDirectRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Update room avatar
 */
ThunkAction<AppState> updateRoomAvatar({String roomId, File localFile}) {
  return (Store<AppState> store) async {
    try {
      final data = await store.dispatch(uploadMedia(
        localFile: localFile,
        mediaName: roomId,
      ));

      final content = {
        'url': data['content_uri'],
      };

      await MatrixApi.sendEvent(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: roomId,
        eventType: EventTypes.avatar,
        content: content,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      await store.dispatch(fetchStateEvents(room: Room(id: roomId)));
      return data['event_id'];
    } catch (error) {
      store.dispatch(
        addAlert(error: error, origin: 'toggleRoomEncryption'),
      );
      return null;
    }
  };
}

/**
 * Toggle Room Encryption On (Only)
 */
ThunkAction<AppState> toggleRoomEncryption({Room room}) {
  return (Store<AppState> store) async {
    try {
      if (room.encryptionEnabled) {
        throw 'Room is already encrypted';
      }

      final content = {
        'algorithm': Algorithms.megolmv1,
      };

      final data = await MatrixApi.sendEvent(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        eventType: EventTypes.encryption,
        content: content,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      await store.dispatch(fetchStateEvents(room: room));
    } catch (error) {
      store.dispatch(addAlert(error: error, origin: 'toggleRoomEncryption'));
    }
  };
}

/**
 * Join Room (by id)
 * 
 * Not sure if this process is / will be any different
 * than accepting an invite
 */
ThunkAction<AppState> joinRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      final data = await MatrixApi.joinRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final rooms = store.state.roomStore.rooms ?? Map<String, Room>();

      Room joinedRoom = rooms.containsKey(room.id)
          ? rooms[room.id]
          : Room(
              id: room.id,
            );

      store.dispatch(SetRoom(
        room: joinedRoom.copyWith(invite: false),
      ));

      await store.dispatch(fetchRooms());
      await store.dispatch(fetchDirectRooms());
    } catch (error) {
      store.dispatch(addAlert(error: error, origin: 'joinRoom'));
    }
  };
}

/**
 * Join Room (by id)
 * 
 * Not sure if this process is / will be any different
 * than accepting an invite
 */
ThunkAction<AppState> inviteUser({
  Room room,
  User user,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.inviteUser(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
        userId: user.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
      return true;
    } catch (error) {
      store.dispatch(
        addAlert(error: error, message: error, origin: 'inviteUser'),
      );
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Accept Room (by id, from invite
 * 
 * Not sure if this process is / will be any different
 * than joining a room
 */
ThunkAction<AppState> acceptRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      final data = await MatrixApi.joinRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final rooms = store.state.roomStore.rooms ?? Map<String, Room>();

      Room joinedRoom = rooms.containsKey(room.id)
          ? rooms[room.id]
          : Room(
              id: room.id,
            );

      store.dispatch(SetRoom(
        room: joinedRoom.copyWith(invite: false),
      ));

      await store.dispatch(fetchRooms());
      await store.dispatch(fetchDirectRooms());
    } catch (error) {
      store.dispatch(addAlert(error: error, origin: 'acceptRoom'));
    }
  };
}

/**
 * Remove Room
 * 
 * Both leaves and forgets room
 */
ThunkAction<AppState> removeRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // submit a leave room request
      final leaveData = await MatrixApi.leaveRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      // Remove the room locally if it's already been removed remotely
      if (leaveData['errcode'] != null) {
        if (leaveData['errcode'] == MatrixErrors.room_unknown) {
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        } else if (leaveData['errcode'] == MatrixErrors.room_not_found) {
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        }

        if (room.direct) {
          await store.dispatch(toggleDirectRoom(room: room, enabled: false));
        }
        throw leaveData['error'];
      }

      final forgetData = await MatrixApi.forgetRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (forgetData['errcode'] != null) {
        if (leaveData['errcode'] == MatrixErrors.room_not_found) {
          await store.dispatch(RemoveRoom(room: Room(id: room.id)));
        }
        if (room.direct) {
          await store.dispatch(toggleDirectRoom(room: room, enabled: false));
        }

        if (room.direct) {
          await store.dispatch(toggleDirectRoom(room: room, enabled: false));
        }
        throw forgetData['error'];
      }

      if (room.direct) {
        await store.dispatch(toggleDirectRoom(room: room, enabled: false));
      }
      await store.dispatch(RemoveRoom(room: Room(id: room.id)));
      store.dispatch(SetLoading(loading: false));
    } catch (error) {
      debugPrint('[removeRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Leave Room
 * 
 * NOTE: https://github.com/vector-im/riot-web/issues/722
 * NOTE: https://github.com/vector-im/riot-web/issues/6978
 * NOTE: https://github.com/matrix-org/matrix-doc/issues/948
 * 
 * Kick all (if owner), tries to delete alias, and leaves
 * TODO: make sure this is in accordance with matrix in that
 * the user can only delete if owning the room, or leave if
 * just a member
 */
ThunkAction<AppState> leaveRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      if (room.direct) {
        await store.dispatch(toggleDirectRoom(room: room, enabled: false));
      }

      final deleteData = await MatrixApi.leaveRoom(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (deleteData['errcode'] != null) {
        if (deleteData['errcode'] == MatrixErrors.room_unknown) {
          store.dispatch(RemoveRoom(room: Room(id: room.id)));
        }
        throw deleteData['error'];
      }
      store.dispatch(RemoveRoom(room: Room(id: room.id)));
    } catch (error) {
      debugPrint('[leaveRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * 
 * Client side temporary hiding only
 */
ThunkAction<AppState> archiveRoom({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(AddArchive(roomId: room.id));
    } catch (error) {
      debugPrint('[archiveRoom] $error');
    }
  };
}

/**
 * Create Draft Room
 * 
 * TODO: make sure this is in accordance with matrix in that
 * A local only room that has not been established with matrix
 * meant to prep a room or first message before actually creating it 
 */
// ThunkAction<AppState> createDraftRoom({
//   String name = 'New Chat',
//   String topic,
//   String avatarUri,
//   List<User> users,
//   bool isDirect = false,
// }) {
//   return (Store<AppState> store) async {
//     try {
//       final draftId = Random.secure().nextInt(1 << 32).toString();

//       final draftRoom = Room(
//         id: draftId,
//         name: name,
//         topic: topic,
//         direct: isDirect,
//         avatarUri: avatarUri,
//         isDraftRoom: true,
//         users: Map.fromIterable(
//           users,
//           key: (user) => user.id,
//           value: (user) => user,
//         ),
//       );

//       await store.dispatch(SetRoom(room: draftRoom));
//       return draftRoom;
//     } catch (error) {
//       return null;
//     }
//   };
// }

/**
 * TODO: Room Drafts
 * 
 * Convert a draft room to a remote matrix room
 */
// ThunkAction<AppState> convertDraftRoom({
//   Room room,
// }) {
//   return (Store<AppState> store) async {
//     try {
//       if (!room.isDraftRoom) {
//         throw 'Room has already been created';
//       }

//       final newRoomId = await store.dispatch(
//         createRoom(
//           name: room.name,
//           topic: room.topic,
//           invites: room.users,
//           isDirect: room.direct,
//         ),
//       );

//       if (newRoomId == null) {
//         throw 'Failed to convert draft room to a real room';
//       }

//       // To temporarily redirect to the new room in the UI
//       return Room(
//         id: newRoomId,
//         name: room.name,
//       );
//     } catch (error) {
//       return null;
//     }
//   };
// }
