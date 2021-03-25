import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/redactions/storage.dart';
import 'package:syphon/store/index.dart';

///
/// Redaction Storage Middleware
///
/// Saves message data to cold storage based
/// on which redux actions are fired, happens
/// BEFORE updating state with
///
dynamic storageMiddlewareRedactions<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  try {
    switch (action.runtimeType) {
      case SetRedactions:
        final redactions = (action as SetRedactions).redactions;
        if (redactions == null || redactions.length == 0) {
          break;
        }
        saveRedactions(redactions, storage: Storage.main);
        break;
      default:
        break;
    }
  } catch (error) {
    printError(error.toString(), tag: 'storageMiddlewareRedactions');
  }

  next(action);
}
