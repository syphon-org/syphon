import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
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

ThunkAction<AppState> startChatObserver() {
  return (Store<AppState> store) async {
    store.dispatch(fetchChats());

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

      print(data);
      print('Fetch Chats Completed');
    } catch (error) {
      print('Fetch Chats Error');
      debugPrint(error);
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

      // TODO: do more here
      print(data);
      print('Syncing Completed');
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
    var chatId = Random.secure().nextInt(10000000).toString();

    store.dispatch(AddChat(
        chat: Chat(
            chatId: chatId,
            title: 'chat-$chatId',
            messages: [],
            syncing: false)));
  };
}
