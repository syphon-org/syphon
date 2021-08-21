import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/context/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';

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
    case SetRoom:
    case RemoveRoom:
    case SetOlmAccount:
    case SetOlmAccountBackup:
    case SetDeviceKeysOwned:
    case SaveKeySession:
    case SetUser:
    case ResetCrypto:
    case ResetUser:
      printInfo('[initStore] persistor saving from ${action.runtimeType}');
      return true;
    default:
      return false;
  }
}
