import './actions.dart';
import './state.dart';

SyncStore syncReducer([SyncStore state = const SyncStore(), dynamic action]) {
  switch (action.runtimeType) {
    case SetLoading:
      return state.copyWith(loading: action.loading);
    case SetSyncing:
      return state.copyWith(syncing: action.syncing);
    case SetSynced:
      return state.copyWith(
        synced: action.synced,
        syncing: action.syncing,
        lastSince: action.lastSince,
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
