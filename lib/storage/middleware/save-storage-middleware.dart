import 'package:redux/redux.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/context/actions.dart';
import 'package:syphon/store/auth/storage.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/storage.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/storage.dart';
import 'package:syphon/store/events/reactions/actions.dart';
import 'package:syphon/store/events/reactions/storage.dart';
import 'package:syphon/store/events/receipts/actions.dart';
import 'package:syphon/store/events/receipts/storage.dart';
import 'package:syphon/store/events/redaction/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/media/storage.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/storage.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/settings/proxy-settings/actions.dart';
import 'package:syphon/store/settings/storage.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/storage.dart';

///
/// Storage Middleware
///
/// Saves state data to cold storage based
/// on which redux actions are fired.
///
saveStorageMiddleware(StorageDatabase? storage) {
  return (
    Store<AppState> store,
    dynamic action,
    NextDispatcher next,
  ) {
    next(action);

    if (storage == null) {
      printWarning('storage is null, skipping saving cold storage data!!!',
          title: 'storageMiddleware');
      return;
    }

    switch (action.runtimeType) {
      case AddAvailableUser:
      case RemoveAvailableUser:
      case SetUser:
        saveAuth(store.state.authStore, storage: storage);
        break;
      case SetUsers:
        final _action = action as SetUsers;
        saveUsers(_action.users ?? {}, storage: storage);
        break;
      case UpdateMediaCache:
        final _action = action as UpdateMediaCache;

        // dont save decrypted images
        final decrypting =
            store.state.mediaStore.mediaStatus[_action.mxcUri] == MediaStatus.DECRYPTING.value;
        if (decrypting) return;

        saveMedia(_action.mxcUri, _action.data,
            info: _action.info, type: _action.type, storage: storage);
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
          saveRoom(room!, storage: storage);
        }
        break;
      case RemoveRoom:
        final _action = action as RemoveRoom;
        final room = store.state.roomStore.rooms[_action.roomId];
        if (room != null) {
          deleteRooms({room.id: room}, storage: storage);
        }
        break;
      case AddReactions:
        final _action = action as AddReactions;
        saveReactions(_action.reactions ?? [], storage: storage);
        break;
      case SaveRedactions:
        final _action = action as SaveRedactions;
        saveMessagesRedacted(_action.redactions ?? [], storage: storage);
        saveReactionsRedacted(_action.redactions ?? [], storage: storage);
        break;
      case SetReceipts:
        final _action = action as SetReceipts;
        final isSynced = store.state.syncStore.synced;
        // TODO: the initial sync loads way too many read receipts
        saveReceipts(_action.receipts ?? {}, storage: storage, ready: isSynced);
        break;
      case SetRoom:
        final _action = action as SetRoom;
        final room = _action.room;
        saveRooms({room.id: room}, storage: storage);
        break;
      case DeleteMessage:
      case DeleteOutboxMessage:
        saveMessages([action.message], storage: storage);
        break;
      case AddMessages:
        final _action = action as AddMessages;
        saveMessages(_action.messages, storage: storage);
        break;
      case AddMessagesDecrypted:
        final _action = action as AddMessagesDecrypted;
        saveDecrypted(_action.messages, storage: storage);
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
      case ToggleAutocorrect:
      case ToggleSuggestions:
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
      case ToggleAutoDownload:
      case ToggleProxy:
      case SetProxyHost:
      case SetProxyPort:
      case ToggleProxyAuthentication:
      case SetProxyUsername:
      case SetProxyPassword:
        saveSettings(store.state.settingsStore, storage: storage);
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
        saveCrypto(store.state.cryptoStore, storage: storage);
        break;
      case SetNotificationSettings:
        // handles updating the background sync thread with new chat settings
        saveNotificationSettings(
          settings: store.state.settingsStore.notificationSettings,
        );
        saveSettings(store.state.settingsStore, storage: storage);
        break;

      default:
        break;
    }
  };
}
