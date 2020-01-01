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

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetSyncing {
  final bool syncing;
  SetSyncing({this.syncing});
}

class SetChatObserver {
  final Timer chatObserver; // testing as a implicit observer
  SetChatObserver({this.chatObserver});
}

class SetChats {
  final List<Chat> chats;
  SetChats({this.chats});
}

class AddChat {
  final Chat chat;
  AddChat({this.chat});
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

ThunkAction<AppState> startChatObserver() {
  return (Store<AppState> store) async {
    final location = await _localPath;
    print(location);
    store.dispatch(fetchChats());
    // store.dispatch(syncChat());

    // Timer chatObserver = Timer.periodic(Duration(seconds: 30), (timer) async {
    //   debugPrint('${timer.tick}');
    //   store.dispatch(syncChat());
    // });

    // store.dispatch(SetChatObserver(chatObserver: chatObserver));
  };
}

ThunkAction<AppState> stopChatObserver() {
  return (Store<AppState> store) async {
    if (store.state.chatStore.chatObserver != null) {
      store.state.chatStore.chatObserver.cancel();
    }
  };
}

ThunkAction<AppState> fetchChats() {
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
      final List<dynamic> joinedRooms = data['joined_rooms'];

      // Convert rooms to chats
      final joinedChats = joinedRooms.map((id) => Chat(id: id)).toList();
      store.dispatch(SetChats(chats: joinedChats));
      print(joinedRooms);

      store.dispatch(fetchChatState(chatId: joinedChats[1].id));
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchChatMembers({String chatId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request =
          buildRoomMembersRequest(accessToken: accessToken, roomId: chatId);

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);

      // Convert rooms to chats
      print(data);
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchChatState({String chatId}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request =
          buildRoomSyncRequest(accessToken: accessToken, roomId: chatId);

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);

      // Convert rooms to chats
      print(data);

      final file = await _localFile;
      file.writeAsString(response.body);
    } catch (error) {
      print(error);
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

// TODO: Fetch whole state if last updated time is null
ThunkAction<AppState> syncChat() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetSyncing(syncing: true));
      print('Syncing Started');

      final isFullState = store.state.chatStore.chats.length == 0;
      final accessToken = store.state.userStore.user.accessToken;
      final homeserver = store.state.userStore.homeserver;

      final request = buildSyncRequest(
        accessToken: accessToken,
        fullState: isFullState,
      );

      final url = "$protocol$homeserver/${request['url']}";
      final response = await http.get(url);
      final data = json.decode(response.body);

      print('Syncing Completed');
      print(data);
    } catch (error) {
      print('Syncing Error');
      debugPrint(error);
    } finally {
      store.dispatch(SetSyncing(syncing: false));
    }
  };
}

// TODO: LEGACY TESTING UI
ThunkAction<AppState> addChat() {
  // return (dispatch, state) =>
  return (Store<AppState> store) async {
    var id = Random.secure().nextInt(10000000).toString();

    store.dispatch(AddChat(
        chat: Chat(id: id, title: 'chat-$id', messages: [], syncing: false)));
  };
}
