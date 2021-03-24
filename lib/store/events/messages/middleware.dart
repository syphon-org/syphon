import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/index.dart';

///
/// Messages Storage Middleware
///
/// Saves message data to cold storage based
/// on which redux actions are fired, happens
/// BEFORE updating state with
///
dynamic messagesStorageMiddleware<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  try {
    switch (action.runtimeType) {
      case SetMessages:
        if (action.messages == null || action.messages.length == 0) break;

        saveMessages(action.messages, storage: Storage.main);
        break;
      default:
        break;
    }
  } catch (error) {
    printError(error.toString(), tag: 'messagesStorageMiddleware');
  }

  next(action);
}
