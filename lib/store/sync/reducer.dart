import './actions.dart';
import './state.dart';

SyncStore syncReducer([SyncStore state = const SyncStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetSyncing:
      return state.copyWith(
        syncing: action.syncing,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
      );
    case SetBackoff:
      return state.copyWith(
        backoff: action.backoff,
      );
    case SetUnauthed:
      return state.copyWith(
        unauthed: action.unauthed,
      );
    case SetBackgrounded:
      return state.copyWith(
        backgrounded: action.backgrounded,
      );
    case SetOffline:
      return state.copyWith(
        offline: action.offline,
      );
    case SetSynced:
      return state.copyWith(
        backoff: 0,
        offline: false,
        synced: action.synced,
        syncing: action.syncing,
        lastSince: action.lastSince,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
        lastUpdate: action.synced
            ? DateTime.now().millisecondsSinceEpoch
            : state.lastUpdate,
      );
    case SetSyncObserver:
      return state.copyWith(
        syncObserver: action.syncObserver,
      );
    case ResetSync:
      return SyncStore();
    default:
      return state;
  }
}
