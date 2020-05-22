import './actions.dart';
import './state.dart';

SyncStore syncReducer([SyncStore state = const SyncStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(
        loading: action.loading,
      );
    case SetBackoff:
      return state.copyWith(
        backoff: action.backoff,
      );
    case SetSyncing:
      return state.copyWith(
        syncing: action.syncing,
      );
    case SetSynced:
      return state.copyWith(
        synced: action.synced,
        syncing: action.syncing,
        lastSince: action.lastSince,
        backoff: action.backoff,
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
