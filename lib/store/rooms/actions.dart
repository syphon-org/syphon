import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/constants.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/receipts/actions.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/settings/models.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';

import 'room/model.dart';

class SetLoading {
  final bool? loading;
  SetLoading({this.loading});
}

class SetRooms {
  final List<Room>? rooms;
  SetRooms({this.rooms});
}

class SetRoom {
  final Room room;
  SetRoom({required this.room});
}

// Atomically Update specific room attributes
class UpdateRoom {
  final String? id; // room id
  final bool? syncing;
  final bool? sending;
  final Message? draft;
  final Message? reply;
  final int? lastRead;

  UpdateRoom({
    this.id,
    this.draft,
    this.reply,
    this.syncing,
    this.sending,
    this.lastRead,
  });
}

class SetReply {
  final bool? clear;
  final Message? reply; // room id

  SetReply({this.clear, this.reply});
}

class RemoveRoom {
  final String? roomId;
  RemoveRoom({this.roomId});
}

class AddArchive {
  final String? roomId;
  AddArchive({this.roomId});
}

class ResetRooms {
  ResetRooms();
}

///
/// Fetch Rooms (w/o /sync)
///
/// Takes a negligible amount of time
///
ThunkAction<AppState> fetchRoom(
  String? roomId, {
  bool direct = false,
  bool fetchState = true,
  bool fetchMessages = true,
  String? userId,
}) {
  return (Store<AppState> store) async {
    try {
      var stateEvents;
      dynamic messageEvents = {};

      if (fetchState) {
        stateEvents = await MatrixApi.fetchStateEvents(
          protocol: store.state.authStore.protocol,
          homeserver: store.state.authStore.user.homeserver,
          accessToken: store.state.authStore.user.accessToken,
          roomId: roomId,
        );

        if (stateEvents is! List && stateEvents['errcode'] != null) {
          throw stateEvents['error'];
        }
      }

      if (fetchMessages) {
        messageEvents = await compute(
          MatrixApi.fetchMessageEventsThreaded,
          {
            'protocol': store.state.authStore.protocol,
            'homeserver': store.state.authStore.user.homeserver,
            'accessToken': store.state.authStore.user.accessToken,
            'roomId': roomId,
            'limit': DEFAULT_LOAD_LIMIT,
          },
        );

        if (messageEvents['errcode'] != null) {
          throw messageEvents['error'];
        }
      }

      final payload = {
        roomId: {
          'state': {
            'events': stateEvents ?? [],
          },
          'timeline': {
            'events': messageEvents['chunk'],
            'curr_batch': messageEvents['start'],
            'prev_batch': messageEvents['end'],
          },
        },
      };

      if (direct) {
        payload[roomId]!['account_data'] = {
          'events': [
            {'type': 'm.direct'}
          ]
        };
      }

      await store.dispatch(syncRooms(payload));
    } catch (error) {
      printError('[fetchRoom] $roomId $error');
    } finally {
      store.dispatch(UpdateRoom(id: roomId, syncing: false));
    }
  };
}

///
/// Fetch Rooms (w/o /sync)
///
/// Takes a negligible amount of time
///
ThunkAction<AppState> fetchRooms({bool syncState = false}) {
  return (Store<AppState> store) async {
    try {
      printInfo('[fetchSync] *** starting fetch all rooms *** ');
      final data = await MatrixApi.fetchRoomIds(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Convert joined_rooms to Room objects
      final joinedRooms = data['joined_rooms'] as List<dynamic>;
      final joinedRoomsList = joinedRooms.map((id) => Room(id: id)).toList();

      await Future.wait(joinedRoomsList.map((room) async {
        try {
          await store.dispatch(fetchRoom(room.id, fetchState: syncState));
          await store.dispatch(fetchRoomMembers(room: room));
        } catch (error) {
          printError('[fetchRoom(s)] ${room.id} $error');
        } finally {
          store.dispatch(UpdateRoom(id: room.id, syncing: false));
        }
      }));
    } catch (error) {
      // WARNING: Silent error, throws error if they have no direct message
      printError('[fetchRoom(s)] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Fetch Direct Rooms
///
/// Fetches both state and message of direct rooms
/// found from account_data of current authed user
///
/// Have to account for multiple direct rooms with one user
/// @riot-bot:matrix.org: [!ajJxpUAIJjYYTzvsHo:matrix.org, !124:matrix.org]
ThunkAction<AppState> fetchDirectRooms() {
  return (Store<AppState> store) async {
    try {
      printInfo('[fetchSync] *** starting fetch direct rooms *** ');
      final data = await MatrixApi.fetchDirectRoomIds(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Mark specified rooms as direct chats
      // convert roomId arrays to one array
      final directRooms = data as Map<String, dynamic>;
      final directRoomList = directRooms.values.expand((x) => x).toList();

      // Wait for all room data to be pulled
      // Fetch room state and messages by userId/roomId
      await Future.wait(directRoomList.map((roomId) async {
        try {
          await store.dispatch(fetchRoom(roomId, direct: true));
        } catch (error) {
          printError('[fetchDirectRooms] $error');
        }
      }));
    } catch (error) {
      printError('[fetchDirectRooms] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

///
/// Fetch Room Members
///
/// Get a map of all the current members of a room
///
ThunkAction<AppState> fetchRoomMembers({
  required Room room,
}) {
  return (Store<AppState> store) async {
    try {
      final _room = store.state.roomStore.rooms[room.id]!;

      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchMembersAll(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: _room.id,
      );

      final members = data['joined'] as Map<String, dynamic>;

      await store.dispatch(setUsers(Map.from(members).map(
        (key, value) => MapEntry(
          key,
          User(
            userId: key,
            avatarUri: value['avatar_url'],
            displayName: value['display_name'],
          ),
        ),
      )));

      store.dispatch(SetRoom(
        room: _room.copyWith(userIds: members.keys.toList()),
      ));
    } catch (error) {
      printError('[updateRoom] $error');
      return null;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Create Room
///
/// stop / start the /sync session for this to run,
/// otherwise it will appear like the room does
/// not exist for the seconds between the response from
/// matrix and caching in the app
ThunkAction<AppState> createRoom({
  String? name,
  String? alias,
  String? topic,
  File? avatarFile,
  String? avatarUri,
  List<User> invites = const <User>[],
  bool isDirect = false,
  bool? encryption = false, // TODO: defaults without group E2EE for now
  String preset = RoomPresets.private,
}) {
  return (Store<AppState> store) async {
    Room? room;
    try {
      store.dispatch(SetLoading(loading: true));
      await store.dispatch(stopSyncObserver());

      final currentUser = store.state.authStore.user;
      final inviteIds = invites.map((user) => user.userId).toList();

      final data = await MatrixApi.createRoom(
        protocol: store.state.authStore.protocol,
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

      // generate user invite map to cache recent users
      room = room.copyWith(usersTEMP: userInviteMap);

      if (isDirect) {
        final User directUser = invites[0];
        room = room.copyWith(
          direct: true,
          name: directUser.displayName ?? directUser.userId,
          // ignore: unnecessary_cast
          userIds: [
            directUser.userId!,
            currentUser.userId!,
          ] as List<String>,
          // ignore: unnecessary_cast
          usersTEMP: {
            directUser.userId!: directUser,
            currentUser.userId!: currentUser,
          } as Map<String, User>,
        );

        await store.dispatch(toggleDirectRoom(room: room, enabled: true));
      }

      // direct chats are encrypted by default
      // group e2ee is not done yet
      if (encryption! || isDirect) {
        await store.dispatch(toggleRoomEncryption(room: room));
      }

      if (avatarFile != null) {
        await store.dispatch(
          updateRoomAvatar(roomId: room.id, localFile: avatarFile),
        );
      }

      await store.dispatch(SetRoom(room: room));

      return room.id;
    } catch (error) {
      store.dispatch(
        addAlert(
          message: error.toString(),
          error: error,
          origin: 'createRoom|$preset',
        ),
      );
      return room?.id;
    } finally {
      await store.dispatch(startSyncObserver());
      store.dispatch(SetLoading(loading: false));
    }
  };
}

///
/// Mark Room Read (Locally Only)
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> markRoomRead({String? roomId}) {
  return (Store<AppState> store) async {
    try {
      final room = store.state.roomStore.rooms[roomId!];
      if (room == null) {
        throw 'Chat not found';
      }

      // mark read locally only
      await store.dispatch(UpdateRoom(
        id: roomId,
        lastRead: DateTime.now().millisecondsSinceEpoch,
      ));

      // send read receipt remotely to mark locally on /sync
      if (store.state.settingsStore.readReceipts != ReadReceiptTypes.Off) {
        final messageLatest = latestMessage(
          roomMessages(store.state, roomId),
        );

        if (messageLatest != null) {
          store.dispatch(sendReadReceipts(
            room: Room(id: roomId),
            message: messageLatest,
          ));
        }
      }
    } catch (error) {
      store.dispatch(addAlert(
        message: 'Failed to mark chat as read',
        error: error,
        origin: 'markRoomRead',
      ));
    }
  };
}

///
/// Mark Room Read (Locally Only)
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> markRoomsReadAll() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final rooms = store.state.roomStore.roomList;

      for (final room in rooms) {
        store.dispatch(markRoomRead(roomId: room.id));
      }
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

/// Toggle Direct Room
///
/// NOTE: https://github.com/matrix-org/matrix-doc/issues/1519
///
/// Fetch the direct rooms list and recalculate it without the
/// given alias
ThunkAction<AppState> toggleDirectRoom({
  required Room room,
  bool enabled = false,
  bool remove = true,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // Pull remote direct room data
      final data = await MatrixApi.fetchDirectRoomIds(
        protocol: store.state.authStore.protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      // Find the other user in the direct room
      final currentUser = store.state.authStore.user;

      // only the other user id, and not the user object, is needed here
      final otherUserId = room.userIds.firstWhereOrNull(
        (userId) => userId != currentUser.userId,
      );

      if (otherUserId == null && enabled) {
        throw 'Cannot toggle room to direct without other users';
      }

      // Pull the direct room for that specific user
      var directRoomUsers = data as Map<String, dynamic>;
      final usersDirectRooms = directRoomUsers[otherUserId] ?? [];

      if (usersDirectRooms.isEmpty && otherUserId != null && enabled) {
        directRoomUsers[otherUserId] = [room.id];
      }

      // Toggle the direct room data based on user actions
      directRoomUsers = directRoomUsers.map((userId, rooms) {
        final List<dynamic> updatedRooms = List.from(rooms ?? []);

        if (userId != otherUserId) {
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
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        userId: store.state.authStore.user.userId,
        type: AccountDataTypes.direct,
        accountData: directRoomUsers,
      );

      if (saveData['errcode'] != null) {
        throw saveData['error'];
      }

      if (remove) {
        await store.dispatch(SetRoom(room: room.copyWith(direct: enabled)));
      }

      // Refresh room information with toggle enabled
      await store.dispatch(fetchRoom(room.id, direct: enabled));
    } catch (error) {
      printError('[toggleDirectRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Update room avatar
ThunkAction<AppState> updateRoomAvatar({
  required String roomId,
  File? localFile,
}) {
  return (Store<AppState> store) async {
    try {
      final data = await store.dispatch(uploadMedia(
        localFile: localFile!,
        mediaName: roomId,
      ));

      final content = {
        'url': data['content_uri'],
      };

      await MatrixApi.sendEvent(
        protocol: store.state.authStore.protocol,
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

/// Toggle Room Encryption On (Only)
ThunkAction<AppState> toggleRoomEncryption({Room? room}) {
  return (Store<AppState> store) async {
    try {
      if (room!.encryptionEnabled) {
        throw 'Room is already encrypted';
      }

      final content = {
        'algorithm': Algorithms.megolmv1,
      };

      final data = await MatrixApi.sendEvent(
        protocol: store.state.authStore.protocol,
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

/// Join Room (by id)
///
/// Not sure if this process is / will be any different
/// than accepting an invite
ThunkAction<AppState> joinRoom({Room? room}) {
  return (Store<AppState> store) async {
    try {
      final data = await MatrixApi.joinRoom(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.alias ?? room.id,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final rooms = store.state.roomStore.rooms;

      final Room joinedRoom = rooms.containsKey(room.id) ? rooms[room.id]! : Room(id: room.id);

      store.dispatch(SetRoom(room: joinedRoom.copyWith(invite: false)));

      store.dispatch(SetLoading(loading: true));
      await store.dispatch(fetchRoom(joinedRoom.id));
      store.dispatch(SetLoading(loading: false));
    } catch (error) {
      store.dispatch(
        addAlert(error: error, origin: 'joinRoom'),
      );
    }
  };
}

/// Invite User (by id)
///
ThunkAction<AppState> inviteUser({
  Room? room,
  User? user,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.inviteUser(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.id,
        userId: user!.userId,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
      return true;
    } catch (error) {
      store.dispatch(
        addAlert(error: error, message: error.toString(), origin: 'inviteUser'),
      );
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Accept Room (by id, from invite
///
/// Not sure if this process is / will be any different
/// than joining a room
ThunkAction<AppState> acceptRoom({required Room room}) {
  return (Store<AppState> store) async {
    try {
      final data = await MatrixApi.joinRoom(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      final rooms = store.state.roomStore.rooms;

      final Room joinedRoom = rooms.containsKey(room.id) ? rooms[room.id]! : Room(id: room.id);
      store.dispatch(SetRoom(room: joinedRoom.copyWith(invite: false)));

      store.dispatch(SetLoading(loading: true));
      await store.dispatch(fetchRoom(joinedRoom.id));
      store.dispatch(SetLoading(loading: false));
    } catch (error) {
      store.dispatch(addAlert(error: error, origin: 'acceptRoom'));
    }
  };
}

///
/// Remove Room
///
/// Both leaves and forgets room
ThunkAction<AppState> removeRoom({Room? room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      if (room!.direct) {
        await store.dispatch(toggleDirectRoom(
          room: room,
          enabled: false,
          remove: false,
        ));
      }

      // submit a leave room request
      final leaveData = await MatrixApi.leaveRoom(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      // remove the room locally if it's already been removed remotely
      if (leaveData['errcode'] != null) {
        if (leaveData['errcode'] != MatrixErrors.room_unknown &&
            leaveData['errcode'] != MatrixErrors.not_found) {
          throw leaveData['error'];
        }
      }

      final forgetData = await MatrixApi.forgetRoom(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (forgetData['errcode'] != null) {
        if (leaveData['errcode'] != MatrixErrors.room_unknown &&
            leaveData['errcode'] != MatrixErrors.not_found) {
          throw leaveData['error'];
        }
      }

      store.dispatch(RemoveRoom(roomId: room.id));
    } catch (error) {
      printError('[removeRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/// Leave Room
///
/// NOTE: https://github.com/vector-im/riot-web/issues/722
/// NOTE: https://github.com/vector-im/riot-web/issues/6978
/// NOTE: https://github.com/matrix-org/matrix-doc/issues/948
///
/// Kick all (if owner), tries to delete alias, and leaves
/// TODO: make sure this is in accordance with matrix in that
/// the user can only delete if owning the room, or leave if
/// just a member
ThunkAction<AppState> leaveRoom({Room? room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      if (room!.direct) {
        await store.dispatch(toggleDirectRoom(
          room: room,
          enabled: false,
          remove: false,
        ));
      }

      final deleteData = await MatrixApi.leaveRoom(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room.id,
      );

      if (deleteData['errcode'] != null) {
        if (deleteData['errcode'] == MatrixErrors.room_unknown) {
          store.dispatch(RemoveRoom(roomId: room.id));
        }
        throw deleteData['error'];
      }

      store.dispatch(RemoveRoom(roomId: room.id));
    } catch (error) {
      printError('[leaveRoom] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

///
/// Client side temporary hiding only
ThunkAction<AppState> archiveRoom({Room? room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(AddArchive(roomId: room!.id));
    } catch (error) {
      printError('[archiveRoom] $error');
    }
  };
}

/**
 * TODO: Create Draft Room
 * 
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
//         draft: true,
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
 * TODO: Convert Draft Room
 * 
 * Convert a draft room to a remote matrix room
 */
// ThunkAction<AppState> convertDraftRoom({
//   Room room,
// }) {
//   return (Store<AppState> store) async {
//     try {
//       if (!room.drafting) {
//         throw 'Room has already been created';
//       }

//       final newRoomId = await store.dispatch(
//         createRoom(
//           name: room.name,
//           topic: room.topic,
//           invites: room.userIds,
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
