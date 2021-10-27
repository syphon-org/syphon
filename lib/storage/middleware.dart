import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/context/actions.dart';
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/events/storage.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/media/storage.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/storage.dart';

///
/// Storage Middleware
///
/// Saves store data to cold storage based
/// on which redux actions are fired.
///
storageMiddleware(Database? storageOld, StorageDatabase? storage) {
  return (
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
  ) {
    next(action);

    if (storageOld == null) {
      printWarning('storage is null, skipping saving cold storage data!!!', title: 'storageMiddleware');
      return;
    }

    switch (action.runtimeType) {
      case AddAvailableUser:
      case RemoveAvailableUser:
      case SetUser:
        saveAuth(store.state.authStore, storage: storageOld);
        break;
      case SetUsers:
        final _action = action as SetUsers;
        saveUsers(_action.users ?? {}, storage: storage!);
        break;
      case UpdateMediaCache:
        final _action = action as UpdateMediaCache;

        // dont save decrypted images
        final decrypting = store.state.mediaStore.mediaStatus[_action.mxcUri] == MediaStatus.DECRYPTING.value;
        if (decrypting) return;

        saveMedia(_action.mxcUri, _action.data, info: _action.info, type: _action.type, storage: storage!);
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
          saveRoom(room!, storage: storage!);
        }
        break;
      case RemoveRoom:
        final _action = action as RemoveRoom;
        final room = store.state.roomStore.rooms[_action.roomId];
        if (room != null) {
          deleteRooms({room.id: room}, storage: storage!);
        }
        break;
      case SetReactions:
        final _action = action as SetReactions;
        saveReactions(_action.reactions ?? [], storage: storageOld);
        break;
      case SetRedactions:
        final _action = action as SetRedactions;
        saveRedactions(_action.redactions ?? [], storage: storageOld);
        break;
      case SetReceipts:
        final _action = action as SetReceipts;
        final isSynced = store.state.syncStore.synced;
        // TODO: the initial sync loads way too many read receipts
        saveReceipts(_action.receipts ?? {}, storage: storageOld, ready: isSynced);
        break;
      case SetRoom:
        final _action = action as SetRoom;
        final room = _action.room;
        saveRooms({room.id: room}, storage: storage!);
        break;
      case AddMessages:
        final _action = action as AddMessages;
        saveMessages(_action.messages, storage: storage!);
        break;
      case AddMessagesDecrypted:
        final _action = action as AddMessagesDecrypted;
        saveDecrypted(_action.messages, storage: storage!);
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
      case SetReadReceipts:
      case LogAppAgreement:
      case SetSyncInterval:
      case SetMainFabLocation:
      case SetMainFabType:
        saveSettings(store.state.settingsStore, storage: storageOld);
        break;
      case SetOlmAccountBackup:
      case SetDeviceKeysOwned:
      case ToggleDeviceKeysExist:
      case SetDeviceKeys:
      case SetOneTimeKeysCounts:
      case SetOneTimeKeysClaimed:
      case AddInboundMessageSession:
      case AddOutboundMessageSession:
      case UpdateMessageSessionOutbound:
      case SaveKeySession:
      case ResetCrypto:
        saveCrypto(store.state.cryptoStore, storage: storageOld);
        break;
      case SetNotificationSettings:
        // handles updating the background sync thread with new chat settings
        saveNotificationSettings(
          settings: store.state.settingsStore.notificationSettings,
        );
        saveSettings(store.state.settingsStore, storage: storageOld);
        break;

      default:
        break;
    }
  };
}
