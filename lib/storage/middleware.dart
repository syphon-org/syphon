import 'package:redux/redux.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/sync/background/storage.dart';

///
/// Storage Middleware
///
/// Saves store data to cold storage based
/// on which redux actions are fired.
///
dynamic storageMiddleware<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  next(action);

  switch (action.runtimeType) {
    // auth store
    case SetUser:
      // printInfo(
      //   '[storageMiddleware] saving auth ${action.runtimeType.toString()}',
      // );
      saveAuth(store.state.authStore, storage: Storage.main!);
      break;
    // media store
    case UpdateMediaCache:
      // printInfo(
      //   '[storageMiddleware] saving media ${action.runtimeType.toString()}',
      // );
      // saveMedia(action.mxcUri, action.data, storage: Storage.main);
      break;
    case UpdateRoom:
      // TODO: create a mutation like SetSyncing to distinguish small but important room mutations
      if (action.syncing == null) {
        // printInfo(
        //   '[storageMiddleware] saving room ${action.runtimeType.toString()}',
        // );
        final room = store.state.roomStore.rooms[action.id];
        if (room != null) {
          saveRoom(room, storage: Storage.main);
        }
      }
      break;
    case SetTheme:
    case SetPrimaryColor:
    case SetAvatarShape:
    case SetAccentColor:
    case SetAppBarColor:
    case SetFontName:
    case SetFontSize:
    case SetMessageSize:
    case SetRoomPrimaryColor:
    case SetDevices:
    case SetLanguage:
    case SetEnterSend:
    case ToggleRoomTypeBadges:
    case ToggleMembershipEvents:
    case ToggleNotifications:
    case ToggleTypingIndicators:
    case ToggleTimeFormat:
    case ToggleReadReceipts:
    case LogAppAgreement:
    case SetSyncInterval:
      saveSettings(store.state.settingsStore, storage: Storage.main!);
      break;
    case SetOlmAccountBackup:
    case SetDeviceKeysOwned:
    case ToggleDeviceKeysExist:
    case SetDeviceKeys:
    case SetOneTimeKeysCounts:
    case SetOneTimeKeysClaimed:
    case AddInboundKeySession:
    case AddInboundMessageSession:
    case AddOutboundKeySession:
    case AddOutboundMessageSession:
    case UpdateMessageSessionOutbound:
    case ResetCrypto:
      saveCrypto(store.state.cryptoStore, storage: Storage.main!);
      break;
    case SetNotificationSettings:
      // handles updating the background sync thread with new chat settings
      saveNotificationSettings(
        settings: store.state.settingsStore.notificationSettings,
      );
      break;

    default:
      break;
  }
}
