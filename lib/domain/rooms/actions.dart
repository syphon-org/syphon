import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/global/libs/matrix/rooms.dart';

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
    final location = await _localPath;
    print(location);
    store.dispatch(fullSync());

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

// TODO: Fetch whole state if last updated time is null
ThunkAction<AppState> fullSync() {
  return (Store<AppState> store) async {
    // TODO: REMOVE THIS, JUST FOR TESTING PARSING A FULL SYNC
    try {
      final syncState = await readFullSyncJson();

      print('** Read State From Disk Successfully **');

      final Map<String, dynamic> rawJoinedRooms = syncState['rooms']['join'];
      print(rawJoinedRooms.keys);

      List<Room> rooms = [];

      rawJoinedRooms.forEach((id, json) {
        json['id'] = id;
        rooms.add(Room.fromJson(json));
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

      final isFullState = store.state.roomStore.rooms.length == 0;
      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request = buildSyncRequest(
        homeserver: homeserver,
        accessToken: accessToken,
        fullState: isFullState,
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

ThunkAction<AppState> fetchRooms() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request = buildJoinedRoomsRequest(
        accessToken: accessToken,
      );

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);
      final List<dynamic> rawJoinedRooms = data['joined_rooms'];

      // Convert joined_rooms to Room objects
      final joinedRooms = rawJoinedRooms.map((id) {
        return Room(id: id);
      }).toList();
      store.dispatch(SetRooms(rooms: joinedRooms));

      // HACK: remove but for testing fetch messages
      // joinedRooms.forEach((room) {
      //   store.dispatch(fetchRoomMessages(roomId: room.id));
      // });
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchRoomMembers({String roomId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request =
          buildRoomMembersRequest(accessToken: accessToken, roomId: roomId);

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);

      // Convert rooms to rooms
      print(data);
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchRoomMessages({String roomId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final startRequest = buildRoomMessagesRequest(
        accessToken: accessToken,
        homeserver: homeserver,
        protocol: protocol,
        roomId: roomId,
      );

      final response = await http.get(startRequest['url']);
      final data = json.decode(response.body);

      print('START DATA ${data['start']}');
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchRoomState({String roomId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request =
          buildRoomStateRequest(accessToken: accessToken, roomId: roomId);

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);

      // Convert rooms to rooms
      print(data);
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
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
