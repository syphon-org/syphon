import 'package:syphon/global/print.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/user/model.dart';

String? selectDirectRoomAvatar(
  Room room,
  String? avatarUri,
  Iterable<User> otherUsers,
) {
  try {
    final shownUser = otherUsers.elementAt(0);

    // set avatar if one has not been assigned
    if (room.avatarUri == null && avatarUri == null && otherUsers.length == 1) {
      return shownUser.avatarUri;
    }

    return avatarUri;
  } catch (error) {
    log.error('[selectDirectRoomAvatar] $error');
    return null;
  }
}

String? selectDirectRoomName(
  User currentUser,
  Iterable<User> otherUsers,
  int totalUsers,
) {
  var roomNameDirect;

  try {
    final total = totalUsers + otherUsers.length;
    final shownUser = otherUsers.elementAt(0);
    final hasMultipleUsers = otherUsers.length > 1;

    // set name and avi to first non user or that + total others
    roomNameDirect = shownUser.displayName;

    if (roomNameDirect == currentUser.displayName) {
      roomNameDirect = '${shownUser.displayName} (${shownUser.userId})';
    }

    if (hasMultipleUsers) {
      roomNameDirect = '${shownUser.displayName} and $total others';
    }

    return roomNameDirect;
  } catch (error) {
    log.error('[selectDirectRoomName] $error');
    return null;
  }
}

bool selectSyncingStatus(AppState state) {
  final synced = state.syncStore.synced;
  final syncing = state.syncStore.syncing;
  final offline = state.syncStore.offline;
  final backgrounded = state.syncStore.backgrounded;
  final loadingRooms = state.roomStore.loading;

  final lastAttempt = DateTime.fromMillisecondsSinceEpoch(state.syncStore.lastAttempt ?? 0);

  // See if the last attempted sy nc is older than 60 seconds
  final isLastAttemptOld = DateTime.now().difference(lastAttempt).compareTo(Duration(seconds: 90));

  // syncing for the first time
  if (syncing && !synced) {
    return true;
  }

  // syncing for the first time since going offline
  if (syncing && offline) {
    return true;
  }

  // joining or removing a room
  if (loadingRooms) {
    return true;
  }

  // syncing for the first time in a while or restarting the app
  if (syncing && (0 < isLastAttemptOld || backgrounded)) {
    return true;
  }

  return false;
}
