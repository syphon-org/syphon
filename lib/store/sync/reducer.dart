import './actions.dart';
import './state.dart';

SyncStore syncReducer([SyncStore state = const SyncStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case SetSyncing:
      final action = actionAny as SetSyncing;
      return state.copyWith(
        syncing: action.syncing,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
      );
    case SetBackoff:
      final action = actionAny as SetBackoff;
      return state.copyWith(
        backoff: action.backoff,
      );
    case SetUnauthed:
      final action = actionAny as SetUnauthed;
      return state.copyWith(
        unauthed: action.unauthed,
      );
    case SetBackgrounded:
      final action = actionAny as SetBackgrounded;
      return state.copyWith(
        backgrounded: action.backgrounded,
      );
    case SetOffline:
      final action = actionAny as SetOffline;
      return state.copyWith(
        offline: action.offline,
      );
    case SetSynced:
      final action = actionAny as SetSynced;
      return state.copyWith(
        backoff: 0,
        offline: false,
        synced: action.synced,
        syncing: action.syncing,
        lastSince: action.lastSince,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
        lastUpdate: action.synced ?? false ? DateTime.now().millisecondsSinceEpoch : state.lastUpdate,
      );
    case SetSyncObserver:
      final action = actionAny as SetSyncObserver;
      return state.copyWith(
        syncObserver: action.syncObserver,
      );
    case ResetSync:
      return SyncStore();
    default:
      return state;
  }
}
