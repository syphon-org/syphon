import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/auth/context/actions.dart';
import 'package:syphon/domain/crypto/actions.dart';
import 'package:syphon/domain/crypto/keys/actions.dart';
import 'package:syphon/domain/crypto/sessions/actions.dart';
import 'package:syphon/domain/events/actions.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/sync/actions.dart';

///
/// Cache Middleware
///
/// Saves store data to cold storage based
/// on which redux actions are fired.
///
bool cacheMiddleware(Store<AppState> store, dynamic action) {
  switch (action.runtimeType) {
    case AddAvailableUser:
    case RemoveAvailableUser:
    case UpdateRoom:
    case SetRoom:
    case RemoveRoom:
    case DeleteMessage:
    case DeleteOutboxMessage:
    case SetOlmAccountBackup:
    case SetDeviceKeysOwned:
    case AddKeySession:
    case AddMessageSessionInbound:
    case AddMessageSessionOutbound:
    case SetUser:
    case ResetCrypto:
    case ResetUser:
      log.info('[initStore] persistor saving from ${action.runtimeType}');
      return true;
    case SetSynced:
      return ((action as SetSynced).synced ?? false) && !store.state.syncStore.synced;
    default:
      return false;
  }
}
