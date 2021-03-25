import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/storage.dart';

///
/// Receipts Storage Middleware
///
/// Saves message data to cold storage based
/// on which redux actions are fired, happens
/// BEFORE updating state with
///
dynamic storageMiddlewareUsers<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  try {
    switch (action.runtimeType) {
      case SetUsers:
        final users = (action as SetUsers).users;
        if (users == null || users.length == 0) {
          break;
        }
        saveUsers(users, storage: Storage.main);
        break;
      default:
        break;
    }
  } catch (error) {
    printError(error.toString(), tag: 'storageMiddlewareUsers');
  }

  next(action);
}
