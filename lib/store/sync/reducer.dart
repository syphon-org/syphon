import './actions.dart';
import './state.dart';

SyncStore syncReducer([SyncStore state = const SyncStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetSyncing:
      final _action = action as SetSyncing;
      return state.copyWith(
        syncing: _action.syncing,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
      );
    case SetBackoff:
      final _action = action as SetBackoff;
      return state.copyWith(
        backoff: _action.backoff,
      );
    case SetUnauthed:
      final _action = action as SetUnauthed;
      return state.copyWith(
        unauthed: _action.unauthed,
      );
    case SetBackgrounded:
      final _action = action as SetBackgrounded;
      return state.copyWith(
        backgrounded: _action.backgrounded,
      );
    case SetOffline:
      final _action = action as SetOffline;
      return state.copyWith(
        offline: _action.offline,
      );
    case SetSynced:
      final _action = action as SetSynced;
      return state.copyWith(
        backoff: 0,
        offline: false,
        synced: _action.synced,
        syncing: _action.syncing,
        lastSince: _action.lastSince,
        lastAttempt: DateTime.now().millisecondsSinceEpoch,
        lastUpdate:
            _action.synced ?? false ? DateTime.now().millisecondsSinceEpoch : state.lastUpdate,
      );
    case SetSyncObserver:
      final _action = action as SetSyncObserver;
      return state.copyWith(
        syncObserver: _action.syncObserver,
      );
    case ResetSync:
      return SyncStore();
    default:
      return state;
  }
}
