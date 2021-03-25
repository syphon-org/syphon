import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/index.dart';

///
/// Receipts Storage Middleware
///
/// Saves message data to cold storage based
/// on which redux actions are fired, happens
/// BEFORE updating state with
///
dynamic storageMiddlewareReceipts<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  try {
    switch (action.runtimeType) {
      case SetReceipts:
        final receipts = (action as SetReceipts).receipts;
        final synced = store.state.syncStore.synced;
        if (receipts == null || receipts.length == 0 || !synced) {
          break;
        }
        saveReceipts(receipts, storage: Storage.main, ready: synced);
        break;
      default:
        break;
    }
  } catch (error) {
    printError(error.toString(), tag: 'storageMiddlewareRedactions');
  }

  next(action);
}
