import 'package:syphon/store/index.dart';

bool selectSyncingStatus(AppState state) {
  final synced = state.syncStore.synced;
  final syncing = state.syncStore.syncing;
  final offline = state.syncStore.offline;
  final backgrounded = state.syncStore.backgrounded;
  final loadingRooms = state.roomStore.loading;

  final lastAttempt =
      DateTime.fromMillisecondsSinceEpoch(state.syncStore.lastAttempt ?? 0);

  // See if the last attempted sy nc is older than 60 seconds
  final isLastAttemptOld =
      DateTime.now().difference(lastAttempt).compareTo(Duration(seconds: 90));

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
