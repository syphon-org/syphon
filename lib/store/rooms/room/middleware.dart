import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/redactions/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/storage.dart';

///
/// Redaction Storage Middleware
///
/// Saves message data to cold storage based
/// on which redux actions are fired, happens
/// BEFORE updating state with
///
dynamic storageMiddlewareRooms<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  try {
    switch (action.runtimeType) {
      case SetRoom:
        final room = (action as SetRoom).room;
        if (room == null) {
          break;
        }
        saveRoom(room, storage: Storage.main);
        break;
      default:
        break;
    }
  } catch (error) {
    printError(error.toString(), tag: 'storageMiddlewareRooms');
  }

  next(action);
}
