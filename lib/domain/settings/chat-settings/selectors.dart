import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/global/colors.dart';

final _chatColorCache = <String, Color>{};

///
/// Chat Color per Chat or Users
///
Color selectChatColor(Store<AppState> store, String? roomId) {
  final chatSettings = store.state.settingsStore.chatSettings;

  // use custom chat color if one has been customized / selected
  if (chatSettings[roomId] != null) {
    return Color(chatSettings[roomId]!.primaryColor);
  }

  // use cached color for roomId to prevent hashing IDs repeatedly
  if (_chatColorCache.containsKey(roomId)) {
    return _chatColorCache[roomId]!;
  }

  final room = store.state.roomStore.rooms[roomId!];
  final currentUserId = store.state.authStore.user.userId;

  // use the userId to generate a color if
  if (room != null && room.direct) {
    final userId = room.userIds.firstWhere((id) => id != currentUserId, orElse: () => '');
    if (userId.isNotEmpty) {
      final chatColor = AppColors.hashedColor(userId);
      _chatColorCache.putIfAbsent(room.id, () => chatColor);
      return chatColor;
    }
  }

  final chatColor = AppColors.hashedColor(roomId);
  _chatColorCache.putIfAbsent(roomId, () => chatColor);
  return chatColor;
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
