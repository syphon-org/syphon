import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:Tether/global/libs/matrix/media.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';
import 'package:Tether/global/libs/matrix/messages.dart';

import 'room/model.dart';
import 'events/model.dart';

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetSyncing {
  final bool syncing;
  SetSyncing({this.syncing});
}

class SetSending {
  final bool sending;
  final Room room;
  SetSending({this.sending, this.room});
}

class SetRoomObserver {
  final Timer roomObserver;
  SetRoomObserver({this.roomObserver});
}

class SetRoom {
  final Room room;
  SetRoom({this.room});
}

class SetRooms {
  final List<Room> rooms;
  SetRooms({this.rooms});
}

class ResetRooms {
  ResetRooms();
}

class SetRoomState {
  final String id; // room id
  final List<Event> state;
  final String username;

  SetRoomState({this.id, this.state, this.username});
}

class SetRoomMessages {
  final String id; // room id
  final String startTime;
  final String endTime;
  final List<Event> messageEvents;

  SetRoomMessages({
    this.id,
    this.startTime,
    this.endTime,
    this.messageEvents,
  });
}

// Atomically Update specific room attributes
class UpdateRoom {
  final String id; // room id
  final Avatar avatar;
  final bool syncing;

  UpdateRoom({
    this.id,
    this.avatar,
    this.syncing,
  });
}

class SetSynced {
  final bool synced;
  final String lastSince;
  SetSynced({this.synced, this.lastSince});
}

/**
 * Initial Room Sync - Custom Solution for /sync
 * 
 * This will only be run on log in because the matrix protocol handles
 * initial syncing terribly. It's incredibly cumbersome to load thousands of events
 * for multiple rooms all at once in order to show the user just some room names
 * and timestamps. Lazy loading isn't always supported, so it's not a solid solution
 */
ThunkAction<AppState> initialRoomSync() {
  return (Store<AppState> store) async {
    // Start initial sync in background
    // TODO: use an isolate for initial sync
    store.dispatch(fetchSync());

    // Fetch All Room Ids
    await store.dispatch(fetchRooms());
    await store.dispatch(fetchDirectRooms());

    // Fetch Essential State and Message Events
    final joinedRooms = store.state.roomStore.roomList;

    final allFetchStates = joinedRooms.map((room) async {
      return store.dispatch(fetchStateEvents(room: room));
    }).toList();

    final allFetchMessages = joinedRooms.map((room) async {
      return store.dispatch(fetchMessageEvents(room: room));
    }).toList();

    // Await all the futures in no particular order
    await Future.wait(
      [allFetchMessages, allFetchStates].expand((x) => x).toList(),
    );
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
ThunkAction<AppState> startRoomsObserver() {
  return (Store<AppState> store) async {
    // Dispatch Background Sync
    Timer roomObserver = Timer.periodic(Duration(seconds: 2), (timer) async {
      if (store.state.roomStore.lastSince != null) {
        store.dispatch(fetchSync(since: store.state.roomStore.lastSince));
      }
    });

    store.dispatch(SetRoomObserver(roomObserver: roomObserver));
  };
}

ThunkAction<AppState> stopRoomsObserver() {
  return (Store<AppState> store) async {
    if (store.state.roomStore.roomObserver != null) {
      store.state.roomStore.roomObserver.cancel();
    }
  };
}

ThunkAction<AppState> fetchSync({String since}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetSyncing(syncing: true));

      final request = buildSyncRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        fullState: store.state.roomStore.rooms == null,
        since: since ?? store.state.roomStore.lastSince,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      // parse sync data
      final data = json.decode(response.body);
      final Map<String, dynamic> rawRooms = data['rooms']['join'];
      final String lastSince = data['next_batch'];

      // init new store containers
      final Map<String, Room> rooms = store.state.roomStore.rooms;
      final user = store.state.userStore.user;

      // update those that exist or add a new room
      rawRooms.forEach((id, json) {
        Room room;

        // use pre-existing values where available
        if (rooms.containsKey(id)) {
          room = rooms[id].fromSync(
            json: json,
            username: user.displayName,
          );
        } else {
          room = Room(id: id).fromSync(
            json: json,
            username: user.displayName,
          );
        }

        // fetch avatar if a uri was found
        if (room.avatar != null) {
          store.dispatch(fetchRoomAvatar(room));
        }

        store.dispatch(SetRoom(room: room));
      });

      // TODO: save the initial sync, but not like this
      if (!store.state.roomStore.synced) {
        final file = await _localFile;
        file.writeAsString(response.body);
      }

      // Set "Synced" and since so we know you've run the inital sync
      store.dispatch(SetSynced(synced: true, lastSince: lastSince));
    } catch (error) {
      print('[fetchSync] error $error');
    } finally {
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

ThunkAction<AppState> fetchRooms() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final request = buildJoinedRoomsRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);
      final List<dynamic> rawJoinedRooms = data['joined_rooms'];

      // Convert joined_rooms to Room objects
      final joinedRooms = rawJoinedRooms.map((id) => Room(id: id)).toList();
      store.dispatch(SetRooms(rooms: joinedRooms));
    } catch (error) {
      print('[fetchRooms] error: $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/*
 Fetch Direct Room Ids
 - fetches id's of direct rooms 
 @riot-bot:matrix.org: [!ajJxpUAIJjYYTzvsHo:matrix.org],
 alekseyparfyonov@gmail.com: [!muTrhMUMwdJSrYlqic:matrix.org] 
*/
ThunkAction<AppState> fetchDirectRooms() {
  return (Store<AppState> store) async {
    try {
      final request = buildDirectRoomsRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: store.state.userStore.user.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final Map<String, dynamic> rawDirectRooms = json.decode(response.body);

      // Mark specified rooms as direct chats
      rawDirectRooms.forEach((name, ids) {
        store.dispatch(SetRoom(room: Room(id: ids[0], direct: true)));
      });
    } catch (error) {
      print('[fetchDirectRooms] error: $error');
    }
  };
}

ThunkAction<AppState> fetchMessageEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(UpdateRoom(id: room.id, syncing: true));

      final request = buildRoomMessagesRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: room.id,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final Map<String, dynamic> messagesJson = json.decode(response.body);
      final String startTime = messagesJson['start'];
      final String endTime = messagesJson['end'];
      final List<dynamic> messagesChunk = messagesJson['chunk'];

      final List<Event> messageEvents =
          messagesChunk.map((event) => Event.fromJson(event)).toList();

      store.dispatch(SetRoomMessages(
        id: room.id,
        messageEvents: messageEvents,
        startTime: startTime,
        endTime: endTime,
      ));
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> fetchStateEvents({Room room}) {
  return (Store<AppState> store) async {
    try {
      // store.dispatch(SetRoom(room: updatedRoom.copyWith(syncing: true)));
      store.dispatch(UpdateRoom(id: room.id, syncing: true));
      final request = buildRoomStateRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: room.id,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final List<dynamic> rawStateEvents = json.decode(response.body);

      // Convert all of the events and save
      final List<Event> stateEvents =
          rawStateEvents.map((event) => Event.fromJson(event)).toList();

      // Add State events to room and toggle syncing
      final user = store.state.userStore.user;

      store.dispatch(SetRoomState(
        id: room.id,
        state: stateEvents,
        username: user.displayName,
      ));

      final updatedRoom = store.state.roomStore.rooms[room.id];
      if (updatedRoom.avatar != null) {
        store.dispatch(fetchRoomAvatar(updatedRoom));
      }
    } catch (error) {
      print('[fetchRoomState] error: ${room.id} $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> fetchMemberEvents({String roomId}) {
  return (Store<AppState> store) async {
    try {
      final request = buildRoomMembersRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: roomId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      // Convert rooms to rooms
      print('$data');
    } catch (error) {
      print(error);
    }
  };
}

ThunkAction<AppState> fetchRoomAvatar(Room room, {bool force}) {
  return (Store<AppState> store) async {
    try {
      if (room.avatar == null || room.avatar.uri == null) {
        throw 'avatar is null';
      }

      final request = buildThumbnailRequest(
        protocol: protocol,
        accessToken: store.state.userStore.user.accessToken,
        homeserver: store.state.userStore.homeserver,
        mediaUri: room.avatar.uri,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      if (response.headers['content-type'] == 'application/json') {
        final errorData = json.decode(response.body);
        throw errorData['errcode'];
      }

      store.dispatch(UpdateRoom(
          id: room.id,
          avatar: room.avatar.copyWith(
              url: request['url'].toString(),
              type: response.headers['content-type'],
              data: response.bodyBytes),
          syncing: false));
    } catch (error) {
      print('[fetchRoomAvatar] error: ${room.id} $error');
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
    }
  };
}

ThunkAction<AppState> loadSync() {
  return (Store<AppState> store) async {
    try {
      // final json = await readFullSyncJson();
      // final json = Cache.hive.get('sync');
      return true;
    } catch (error) {
      debugPrint(error);
      return false;
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
    print(error);
    return null;
  } finally {
    print('** Read State From Disk Successfully **');
  }
}
