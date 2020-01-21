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

class SetRoomObserver {
  final Timer roomObserver; // testing as a implicit observer
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

class SetRoomState {
  final String id; // room id
  final List<Event> state;
  final String username;

  SetRoomState({this.id, this.state, this.username});
}

class SetRoomMessages {
  final String id; // room id
  final Map<String, dynamic> messagesJson;
  SetRoomMessages({this.id, this.messagesJson});
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
    if (store.state.roomStore.rooms == null ||
        store.state.roomStore.rooms.isEmpty) {
      await store.dispatch(fetchRooms());
      await store.dispatch(fetchDirectRooms());
    }

    // Fetch All Room State
    final joinedRooms = store.state.roomStore.roomList;

    final allFetchStates = joinedRooms.map((room) async {
      if (room.state.length > 0) return;
      return store.dispatch(fetchRoomState(room: room));
    }).toList();

    final allFetchMessages = joinedRooms.map((room) async {
      return store.dispatch(fetchRoomMessages(room: room));
    }).toList();

    await Future.wait(allFetchMessages + allFetchStates);

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

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final Map<String, dynamic> rawDirectRooms = json.decode(response.body);

      // Mark specified rooms as direct chats
      rawDirectRooms.forEach((name, ids) {
        store.dispatch(SetRoom(
            room: Room(
          id: ids[0],
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

ThunkAction<AppState> fetchRoomMessages({Room room}) {
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

      store.dispatch(SetRoomMessages(id: room.id, messagesJson: messagesJson));
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(UpdateRoom(id: room.id, syncing: false));
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

// TODO: Fetch whole state if last updated time is null
ThunkAction<AppState> fullSync() {
  return (Store<AppState> store) async {
    // TODO: REMOVE THIS, JUST FOR TESTING PARSING A FULL SYNC
    try {
      final syncState = await readFullSyncJson();

      print('** Read State From Disk Successfully **');

      final List<Room> rooms = [];
      final Map<String, dynamic> rawRooms = syncState['rooms']['join'];

      rawRooms.forEach((id, json) => rooms.add(Room.fromSync(
            id: id,
            json: json,
          )));

      print(rooms);

      store.dispatch(SetRooms(rooms: rooms));
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

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );
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
