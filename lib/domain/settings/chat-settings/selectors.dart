import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/global/colors.dart';

final _chatColorCache = <String, Color>{};

///
/// Chat Color per Chat or Users
///
Color selectChatColor(AppState state, String? roomId) {
  final chatSettings = state.settingsStore.chatSettings;

  // use custom chat color if one has been customized / selected
  if (chatSettings[roomId] != null) {
    return Color(chatSettings[roomId]!.primaryColor);
  }

  // use cached color for roomId to prevent hashing IDs repeatedly
  if (_chatColorCache.containsKey(roomId)) {
    return _chatColorCache[roomId]!;
  }

  final room = state.roomStore.rooms[roomId!];
  final currentUserId = state.authStore.user.userId;

  // use the userId to generate a color if a direct chat
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
Color? selectBubbleColor(AppState state, String? roomId) {
  final chatSettings = state.settingsStore.chatSettings;
  final chatSetting = chatSettings[roomId];

  if (chatSetting == null) return null;

  return Color(chatSetting.primaryColor);
}
