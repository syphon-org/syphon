import 'package:redux/redux.dart';
import 'package:syphon/domain/auth/actions.dart';
import 'package:syphon/domain/auth/context/actions.dart';
import 'package:syphon/domain/auth/storage.dart';
import 'package:syphon/domain/crypto/actions.dart';
import 'package:syphon/domain/crypto/keys/actions.dart';
import 'package:syphon/domain/crypto/sessions/actions.dart';
import 'package:syphon/domain/crypto/sessions/storage.dart';
import 'package:syphon/domain/crypto/storage.dart';
import 'package:syphon/domain/events/actions.dart';
import 'package:syphon/domain/events/messages/storage.dart';
import 'package:syphon/domain/events/reactions/actions.dart';
import 'package:syphon/domain/events/reactions/storage.dart';
import 'package:syphon/domain/events/receipts/actions.dart';
import 'package:syphon/domain/events/receipts/storage.dart';
import 'package:syphon/domain/events/redaction/actions.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/media/actions.dart';
import 'package:syphon/domain/media/model.dart';
import 'package:syphon/domain/media/storage.dart';
import 'package:syphon/domain/rooms/actions.dart';
import 'package:syphon/domain/rooms/storage.dart';
import 'package:syphon/domain/settings/actions.dart';
import 'package:syphon/domain/settings/chat-settings/actions.dart';
import 'package:syphon/domain/settings/notification-settings/actions.dart';
import 'package:syphon/domain/settings/privacy-settings/actions.dart';
import 'package:syphon/domain/settings/privacy-settings/storage.dart';
import 'package:syphon/domain/settings/proxy-settings/actions.dart';
import 'package:syphon/domain/settings/storage-settings/actions.dart';
import 'package:syphon/domain/settings/storage.dart';
import 'package:syphon/domain/settings/theme-settings/actions.dart';
import 'package:syphon/domain/sync/service/storage.dart';
import 'package:syphon/domain/user/actions.dart';
import 'package:syphon/domain/user/storage.dart';
import 'package:syphon/global/libraries/storage/database.dart';
import 'package:syphon/global/print.dart';

///
/// Storage Middleware
///
/// Saves state data to cold storage based
/// on which redux actions are fired.
///
saveStorageMiddleware(StorageDatabase? storage) {
  return (
    Store<AppState> store,
    // ignore: no_leading_underscores_for_local_identifiers
    dynamic _action,
    NextDispatcher next,
  ) {
    next(_action);

    if (storage == null) {
      log.warn('storage is null, skipping saving cold storage data!!!', title: 'storageMiddleware');
      return;
    }

    switch (_action.runtimeType) {
      case AddAvailableUser:
      case RemoveAvailableUser:
      case SetUser:
        saveAuth(store.state.authStore, storage: storage);
        break;
      case SetUsers:
        final action = _action as SetUsers;
        saveUsers(action.users ?? {}, storage: storage);
        break;
      case UpdateMediaCache:
        final action = _action as UpdateMediaCache;

        // dont save decrypted images
        final decrypting = store.state.mediaStore.mediaStatus[action.mxcUri] == MediaStatus.DECRYPTING.value;
        if (decrypting) return;

        saveMedia(action.mxcUri, action.data, info: action.info, type: action.type, storage: storage);
        break;
      case UpdateRoom:
        final action = _action as UpdateRoom;
        final rooms = store.state.roomStore.rooms;
        final isSending = action.sending != null;
        final isDrafting = action.draft != null;
        final isLastRead = action.lastRead != null;

        if ((isSending || isDrafting || isLastRead) && rooms.containsKey(action.id)) {
          final room = rooms[action.id];
          saveRoom(room!, storage: storage);
        }
        break;
      case RemoveRoom:
        final action = _action as RemoveRoom;
        final room = store.state.roomStore.rooms[action.roomId];
        if (room != null) {
          deleteRooms({room.id: room}, storage: storage);
        }
        break;
      case AddReactions:
        final action = _action as AddReactions;
        saveReactions(action.reactions ?? [], storage: storage);
        break;
      case SaveRedactions:
        final action = _action as SaveRedactions;
        saveMessagesRedacted(action.redactions ?? [], storage: storage);
        saveReactionsRedacted(action.redactions ?? [], storage: storage);
        break;
      case SetReceipts:
        final action = _action as SetReceipts;
        final isSynced = store.state.syncStore.synced;
        // NOTE: prevents saving read receipts until a Full Sync is completed
        saveReceipts(action.receipts ?? {}, storage: storage, ready: isSynced);
        break;
      case SetRoom:
        final action = _action as SetRoom;
        final room = action.room;
        saveRooms({room.id: room}, storage: storage);
        break;
      case DeleteMessage:
        saveMessages([_action.message], storage: storage);
        break;
      case DeleteOutboxMessage:
        deleteMessages([_action.message], storage: storage);
        break;
      case AddMessages:
        final action = _action as AddMessages;
        saveMessages(action.messages, storage: storage);
        break;
      case AddMessagesDecrypted:
        final action = _action as AddMessagesDecrypted;
        saveDecrypted(action.messages, storage: storage);
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
      case SetSyncInterval:
      case SetMainFabLocation:
      case SetMainFabType:
      case ToggleAutoDownload:
      case ToggleProxy:
      case SetProxyHost:
      case SetProxyPort:
      case SetKeyBackupInterval:
      case SetKeyBackupLocation:
      case ToggleProxyAuthentication:
      case SetProxyUsername:
      case SetProxyPassword:
      case SetLastBackupMillis:
        saveSettings(store.state.settingsStore, storage: storage);
        break;
      case SetKeyBackupPassword:
        final action = _action as SetKeyBackupPassword;
        saveBackupPassword(password: action.password);
        break;
      case LogAppAgreement:
        saveTermsAgreement(timestamp: int.parse(store.state.settingsStore.alphaAgreement ?? '0'));
        break;
      case SetOlmAccountBackup:
      case SetDeviceKeysOwned:
      case ToggleDeviceKeysExist:
      case SetDeviceKeys:
      case SetOneTimeKeysCounts:
      case SetOneTimeKeysClaimed:
      case AddMessageSessionOutbound:
      case UpdateMessageSessionOutbound:
      case AddKeySession:
      case ResetCrypto:
        saveCrypto(store.state.cryptoStore, storage: storage);
        break;
      case AddMessageSessionInbound:
        final action = _action as AddMessageSessionInbound;
        saveMessageSessionInbound(
          roomId: action.roomId,
          identityKey: action.senderKey,
          session: action.session,
          messageIndex: action.messageIndex,
          storage: storage,
        );
        break;
      case SaveMessageSessionsInbound:
        saveMessageSessionsInbound(
          store.state.cryptoStore.messageSessionsInbound,
          storage: storage,
        );
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
