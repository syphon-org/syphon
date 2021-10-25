import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import './model.dart';

/*
 * Selectors
 */
dynamic homeserver(AppState state) {
  return state.authStore.homeserver;
}

// Users the authed user has dm'ed
List<User> selectFriendlyUsers(AppState state) {
  final rooms = state.roomStore.rooms.values;
  final users = state.userStore.users;
  final userCurrent = state.authStore.user;
  final roomsDirect = rooms.where((room) => room.direct);
  final roomUserIdsList = roomsDirect.map((room) => room.userIds);
  final roomDirectUserIdsAll = roomUserIdsList.expand((pair) => pair).toList();
  final roomDirectUserIds = roomDirectUserIdsAll
    ..retainWhere(
      (userId) => userId != userCurrent.userId && users.containsKey(userId),
    );
  final roomsDirectUsers = roomDirectUserIds.map((userId) => users[userId]);

  return List.from(roomsDirectUsers);
}

// Users the authed user has dm'ed
List<User> selectKnownUsers(AppState state) {
  final users = state.userStore.users;
  final latestUsers = users.values.take(25);
  return List.from(latestUsers);
}

List<User?> roomUsers(AppState state, String? roomId) {
  final room = state.roomStore.rooms[roomId!] ?? Room(id: roomId);
  return room.userIds.map((userId) => state.userStore.users[userId]).toList();
}

Map<String, User> messageUsers({required AppState state, String? roomId}) {
  final messages = state.eventStore.messages[roomId] ?? [];
  return Map.fromIterable(
    messages,
    key: (msg) => msg.sender,
    value: (msg) => state.userStore.users[msg.sender] ?? User(),
  );
}

/*
 * Getters
 */
String trimAlias(String? alias) {
  // If user has yet to save a displayName, format the userId to show like one
  return alias != null ? alias.split(':')[0].replaceAll('@', '') : '';
}

String formatAlias({String resource = '', String homeserver = ''}) {
  // ignore: prefer_interpolation_to_compose_strings
  return '@' + resource + ':' + homeserver;
}

String formatUsername(User user) {
  return user.displayName ?? trimAlias(user.userId ?? '');
}

String safeUserId(User? user) {
  return user != null
      ? user.userId ?? Values.defaultUserId
      : Values.defaultUserId;
}

String formatUserInitials(User? user) {
  if (user == null || (user.displayName == null && user.userId == null)) {
    return '';
  }

  return formatInitialsLong(user.displayName ?? user.userId);
}

List<User?> searchUsersLocal(
  AppState state, {
  String? roomId,
  String? searchText = '',
}) {
  final users = roomUsers(state, roomId);
  if (searchText == null || searchText.isEmpty) {
    return users;
  }

  return List.from(users.where(
    (user) =>
        (user!.displayName ?? '').contains(searchText) ||
        (user.userId ?? '').contains(searchText),
  ));
}
