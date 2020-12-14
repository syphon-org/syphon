// Project imports:
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
List<User> friendlyUsers(AppState state) {
  final rooms = state.roomStore.rooms.values;
  final users = state.userStore.users;
  final userCurrent = state.authStore.user.userId;
  final roomsDirect = rooms.where((room) => room.direct);
  final roomUserIdsList = roomsDirect.map((room) => room.userIds);
  final roomDirectUserIdsAll = roomUserIdsList.expand((pair) => pair).toList();
  final roomDirectUserIds = roomDirectUserIdsAll..remove(userCurrent);
  final roomsDirectUsers = roomDirectUserIds.map((userId) => users[userId]);

  return List.from(roomsDirectUsers);
}

/*
 * Getters
 */
String trimAlias(String alias) {
  // If user has yet to save a displayName, format the userId to show like one
  return alias != null ? alias.split(':')[0].replaceAll('@', '') : '';
}

String formatAlias({String resource = '', String homeserver = ''}) {
  return "@" + resource + ":" + homeserver;
}

String formatUsername(User user) {
  return user.displayName ?? trimAlias(user.userId ?? '');
}

String formatInitials(String fullword) {
  //  -> ?
  if (fullword == null || fullword.isEmpty) {
    return '?';
  }

  // example words -> EW
  if (fullword.contains(' ') && fullword.split(' ')[1].isNotEmpty) {
    final words = fullword.split(' ');
    final initialOne = words.elementAt(0).substring(0, 1);
    final initialTwo = words.elementAt(1).substring(0, 1);

    return (initialOne + initialTwo).toUpperCase();
  }

  // example words -> EX
  final word = fullword.replaceAll('@', '');
  final initials =
      word.length > 1 ? word.substring(0, 2) : word.substring(0, 1);

  return initials.toUpperCase();
}

List<User> roomUsers(AppState state, String roomId) {
  final room = state.roomStore.rooms[roomId] ?? Room(id: roomId);
  return room.userIds.map((userId) => state.userStore.users[userId]).toList();
}

List<User> searchUsersLocal(
  AppState state, {
  String roomId,
  String searchText = '',
}) {
  var users = roomUsers(state, roomId);
  if (searchText == null || searchText.isEmpty) {
    return users;
  }

  return List.from(users.where(
    (user) =>
        (user.displayName ?? '').contains(searchText) ||
        (user.userId ?? '').contains(searchText),
  ));
}
