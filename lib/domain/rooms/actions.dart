import 'dart:async';
import 'dart:io';
import 'dart:math';
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

import './model.dart';
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

class SetRoomObserver {
  final Timer roomObserver; // testing as a implicit observer
  SetRoomObserver({this.roomObserver});
}

class SetRooms {
  final List<Room> rooms;
  SetRooms({this.rooms});
}

class UpdateRoom {
  final Room room;
  UpdateRoom({this.room});
}

class AddRoom {
  final Room room;
  AddRoom({this.room});
}

// TODO: REMOVE - ONLY FOR TESTING OUTPUT
Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();

  return directory.path;
}

// TODO: REMOVE - ONLY FOR TESTING OUTPUT
Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/matrix.json');
}

Future<dynamic> readFullSyncJson() async {
  try {
    final file = await _localFile;
    String contents = await file.readAsString();
    return await jsonDecode(contents);
  } catch (error) {
    // If encountering an error, return 0.
    print(error);
    return null;
  }
}

ThunkAction<AppState> startRoomsObserver() {
  return (Store<AppState> store) async {
    // Fetch All Room Ids
    await store.dispatch(fetchRooms());
    await store.dispatch(fetchDirectRooms());
    final sortedDirectRooms = store.state.roomStore.rooms;

    // TODO: Refactor this to be logical based on direct but also update timestamps
    sortedDirectRooms.sort((a, b) => a.direct && !b.direct ? -1 : 1);
    store.dispatch(SetRooms(rooms: sortedDirectRooms));

    // Fetch All Room State
    final joinedRooms = store.state.roomStore.rooms;
    await Future.wait(joinedRooms.map((room) async {
      return store.dispatch(fetchRoomState(room: room));
    }).toList());

    // Dispatch Background Sync
    // store.dispatch(fullSync());

    // Timer roomObserver = Timer.periodic(Duration(seconds: 30), (timer) async {
    //   debugPrint('${timer.tick}');
    //   store.dispatch(syncRoom());
    // });

    // store.dispatch(SetRoomObserver(roomObserver: roomObserver));
  };
}

ThunkAction<AppState> stopRoomsObserver() {
  return (Store<AppState> store) async {
    if (store.state.roomStore.roomObserver != null) {
      store.state.roomStore.roomObserver.cancel();
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

      final response = await http.get(request['url']);
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
{
 @riot-bot:matrix.org: [!ajJxpUAIJjYYTzvsHo:matrix.org],
 alekseyparfyonov@gmail.com: [!muTrhMUMwdJSrYlqic:matrix.org]
}
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

      final response = await http.get(request['url']);
      final Map<String, dynamic> rawDirectRooms = json.decode(response.body);

      // Mark specified rooms as direct chats
      rawDirectRooms.forEach((name, roomIds) {
        store.dispatch(UpdateRoom(
            room: Room(
          id: roomIds[0],
          name: name,
          direct: true,
        )));
      });
    } catch (error) {
      print('[fetchDirectRooms] error: $error');
    }
  };
}

ThunkAction<AppState> fetchRoomState({Room room}) {
  return (Store<AppState> store) async {
    var updatedRoom = room;
    try {
      store.dispatch(UpdateRoom(room: updatedRoom.copyWith(syncing: true)));

      final request = buildRoomStateRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: updatedRoom.id,
      );

      final response = await http.get(request['url']);
      final List<dynamic> rawStateEvents = json.decode(response.body);

      // Convert all of the events and save
      final List<Event> stateEvents =
          rawStateEvents.map((event) => Event.fromJson(event)).toList();

      // Add State events to room and toggle syncing
      final user = store.state.userStore.user;
      updatedRoom = updatedRoom.fromStateEvents(stateEvents,
          currentUsername: user.displayName);

      if (updatedRoom.avatar != null) {
        updatedRoom = await store.dispatch(fetchRoomAvatar(updatedRoom));
      }
    } catch (error) {
      print('[fetchRoomState] error: ${room.id} $error');
    } finally {
      store.dispatch(UpdateRoom(room: updatedRoom.copyWith(syncing: false)));
    }
  };
}

ThunkAction<AppState> fetchRoomAvatar(
  Room room,
) {
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

      final response = await http.get(request['url']);

      if (response.headers['content-type'] == 'application/json') {
        final errorData = json.decode(response.body);
        throw errorData['errcode'];
      }

      return room.copyWith(
          syncing: false,
          avatar: room.avatar.copyWith(
              url: request['url'].toString(),
              type: response.headers['content-type'],
              data: response.bodyBytes));
    } catch (error) {
      print('[fetchRoomAvatar] error: ${room.id} $error');
      return room;
    }
  };
}

// TODO: Fetch whole state if last updated time is null
ThunkAction<AppState> fullSync() {
  return (Store<AppState> store) async {
    // TODO: REMOVE THIS, JUST FOR TESTING PARSING A FULL SYNC
    try {
      final syncState = await readFullSyncJson();

      print('** Read State From Disk Successfully **');

      final Map<String, dynamic> rawJoinedRooms = syncState['rooms']['join'];
      List<Room> rooms = [];

      rawJoinedRooms.forEach((id, json) {
        json['id'] = id;
        rooms.add(Room.fromJsonSync(json));
      });

      store.dispatch(SetRooms(rooms: rooms));
      print(rooms);
      return true;
    } catch (error) {
      debugPrint(error);
    }

    try {
      store.dispatch(SetSyncing(syncing: true));
      print('Syncing Started');

      final request = buildSyncRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        fullState: store.state.roomStore.rooms.length == 0,
      );

      final response = await http.get(request['url']);
      final data = json.decode(response.body);

      print('Syncing Completed');
      final file = await _localFile;
      file.writeAsString(response.body);
    } catch (error) {
      print('Syncing Error');
      debugPrint(error);
    } finally {
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

ThunkAction<AppState> fetchRoomMembers({String roomId}) {
  return (Store<AppState> store) async {
    try {
      final request = buildRoomMembersRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: roomId,
      );

      final response = await http.get(request['url']);
      final data = json.decode(response.body);

      // Convert rooms to rooms
      print('$data');
    } catch (error) {
      print(error);
    }
  };
}

ThunkAction<AppState> fetchRoomMessages({Room room}) {
  return (Store<AppState> store) async {
    try {
      final startRequest = buildRoomMessagesRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        roomId: room.id,
      );

      final response = await http.get(startRequest['url']);
      final data = json.decode(response.body);

      print('Room Messages ${data['start']}');
    } catch (error) {
      print(error);
    }
  };
}

// TODO: LEGACY TESTING UI
ThunkAction<AppState> addRoom() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    var id = Random.secure().nextInt(10000000).toString();

    store.dispatch(AddRoom(
        room: Room(id: id, name: 'room-$id', events: [], syncing: false)));
  };
}
