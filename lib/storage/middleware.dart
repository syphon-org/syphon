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
storageMiddleware<State>(
  Store<AppState> store,
  dynamic action,
  NextDispatcher next,
) {
  next(action);

  switch (action.runtimeType) {
    case SetUser:
      saveAuth(store.state.authStore, storage: Storage.instance!);
      break;
    case UpdateMediaCache:
      // saveMedia(action.mxcUri, action.data, storage: Storage.main);
      break;
    case UpdateRoom:
      final _action = action as UpdateRoom;
      final rooms = store.state.roomStore.rooms;
      final isSending = _action.sending != null;
      final isDrafting = _action.draft != null;
      final isLastRead = _action.lastRead != null;

      // room information (or a room) should be small enought to update frequently
      // TODO: extract room event keys to a helper class / object to remove large map copies
      if ((isSending || isDrafting || isLastRead) && rooms.containsKey(_action.id)) {
        final room = rooms[_action.id];
        saveRoom(room!, storage: Storage.instance);
      }
      break;
    case RemoveRoom:
      final _action = action as RemoveRoom;
      final room = store.state.roomStore.rooms[_action.roomId];
      if (room != null) {
        deleteRooms({room.id: room}, storage: Storage.instance);
      }
      break;
    case SetThemeType:
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
    case ToggleEnterSend:
    case ToggleRoomTypeBadges:
    case ToggleMembershipEvents:
    case ToggleNotifications:
    case ToggleTypingIndicators:
    case ToggleTimeFormat:
    case ToggleReadReceipts:
    case LogAppAgreement:
    case SetSyncInterval:
      saveSettings(store.state.settingsStore, storage: Storage.instance!);
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
      saveCrypto(store.state.cryptoStore, storage: Storage.instance!);
      break;
    case SetNotificationSettings:
      // handles updating the background sync thread with new chat settings
      saveNotificationSettings(
        settings: store.state.settingsStore.notificationSettings,
      );
      saveSettings(store.state.settingsStore, storage: Storage.instance!);
      break;

    default:
      break;
  }
}
