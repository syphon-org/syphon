import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/state.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/index.dart';

/// Middleware used for Redux which saves on each action.
dynamic storageMiddleware<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  next(action);

  switch (action.runtimeType) {
    // crypto store - CUD ops
    case SetOlmAccountBackup:
    case SetDeviceKeysOwned:
    case ToggleDeviceKeysExist:
    case SetDeviceKeys:
    case SetOneTimeKeysClaimed:
    case SetOneTimeKeysCounts:
    case AddInboundKeySession:
    case AddOutboundKeySession:
    case AddOutboundMessageSession:
    case ResetCrypto:
      printInfo(
        '[storageMiddleware] saving crypto ${action.runtimeType.toString()}',
      );
      saveCrypto(store.state.cryptoStore, storage: Storage.main);
      break;
    default:
      break;
  }
}
