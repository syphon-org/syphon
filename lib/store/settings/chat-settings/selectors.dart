import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/store/index.dart';

///
/// Chat Color per User
///
Color selectChatColor(Store<AppState> store, String? roomId) {
  final chatSettings = store.state.settingsStore.chatSettings;

  if (chatSettings[roomId] == null) {
    return Colours.hashedColor(roomId);
  }

  return Color(chatSettings[roomId]!.primaryColor);
}

///
/// Chat Bubble Color per User
///
Color? selectBubbleColor(Store<AppState> store, String? roomId) {
  final chatSettings = store.state.settingsStore.chatSettings;

  if (chatSettings[roomId] == null) {
    return null;
  }

  return Color(chatSettings[roomId]!.primaryColor);
}
