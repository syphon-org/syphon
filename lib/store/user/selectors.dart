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
  final rooms = state.roomStore.rooms.values as Iterable<Room>;
  final roomsDirect = rooms.where((room) => room.direct);
  final roomsDirectUsers = roomsDirect.map((room) => room.users);

  final allDirectUsers = roomsDirectUsers.fold(
    {},
    (usersAll, users) {
      (usersAll as Map).addAll(users);
      return usersAll;
    },
  );

  return List.from(allDirectUsers.values);
}

/*
 * Getters
 */
String trimmedUserId({String userId}) {
  return userId.replaceAll('@', '');
}

String userAlias({String username, String homeserver}) {
  return "@" + username + ":" + homeserver;
}

String matrixAlias({String resource, String homeserver}) {
  return "@" + resource + ":" + homeserver;
}

String formatShortname(String userId) {
  // If user has yet to save a username, format the userId to show the shortname
  return userId != null ? userId.split(':')[0].replaceAll('@', '') : '';
}

String displayShortname(User user) {
  // If user has yet to save a username, format the userId to show the shortname
  return user.userId != null
      ? user.userId.split(':')[0].replaceAll('@', '')
      : '';
}

String formatDisplayName(User user) {
  return user.displayName ?? displayShortname(user);
}

String formatInitials(String fullword) {
  if (fullword == null) {
    return '?';
  }

  final word = fullword.replaceAll('@', '');

  final initials =
      word.length > 1 ? word.substring(0, 2) : word.substring(0, 1);

  return initials.toUpperCase();
}

String displayInitials(User user) {
  final userId = user.userId ?? 'Unknown';
  final displayName = user.displayName ?? userId.replaceFirst('@', '');

  if (displayName.length > 0) {
    final initials = displayName.length > 1
        ? displayName.substring(0, 2)
        : userId.substring(0, 1);

    return initials.toUpperCase();
  }

  if (userId.length > 0) {
    final initials =
        userId.length > 1 ? userId.substring(0, 2) : userId.substring(0, 1);
    return initials.toUpperCase();
  }

  return 'NA';
}

List<User> searchUsersLocal(List<User> users, {String searchText = ''}) {
  if (searchText == null || searchText.isEmpty) {
    return users;
  }

  return List.from(users.where(
    (user) =>
        (user.displayName ?? '').contains(searchText) ||
        (user.userId ?? '').contains(searchText),
  ));
}
