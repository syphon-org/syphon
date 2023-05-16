import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/domain/events/messages/model.dart';
import 'package:syphon/domain/events/receipts/model.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/rooms/room/model.dart';
import 'package:syphon/domain/settings/actions.dart';
import 'package:syphon/domain/settings/models.dart';

class SetReceipts {
  final String? roomId;
  final Map<String, Receipt>? receipts;
  SetReceipts({this.roomId, this.receipts});
}

class LoadReceipts {
  final Map<String, Map<String, Receipt>> receiptsMap;
  LoadReceipts({required this.receiptsMap});
}

ThunkAction<AppState> setReceipts({
  Room? room,
  Map<String, Receipt>? receipts,
}) =>
    (Store<AppState> store) {
      if (receipts!.isEmpty) return;
      return store.dispatch(SetReceipts(roomId: room!.id, receipts: receipts));
    };

///
/// Read Message Marker
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> sendReadReceipts({
  Room? room,
  Message? message,
  bool readAll = true,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if Read Receipts are disabled
      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Off) {
        return log.info('[sendReadReceipts] read receipts disabled');
      }

      final data;

      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Private) {
        log.info('[sendReadReceipts] read receipts set to private');

        data = await MatrixApi.sendPrivateReadReceipt(
          protocol: store.state.authStore.protocol,
          accessToken: store.state.authStore.user.accessToken,
          homeserver: store.state.authStore.user.homeserver,
          roomId: room!.id,
          messageId: message!.id,
          stable: await homeserverSupportsPrivateReadReceipts(store), //@deprecated
        );
      } else {
        data = await MatrixApi.sendReadReceipts(
          protocol: store.state.authStore.protocol,
          accessToken: store.state.authStore.user.accessToken,
          homeserver: store.state.authStore.user.homeserver,
          roomId: room!.id,
          messageId: message!.id,
          readAll: readAll,
        );
      }

      if (data['errcode'] != null) {
        throw data['error'];
      }

      log.info('[sendReadReceipts] sent ${message.id} $data');
    } catch (error) {
      log.info('[sendReadReceipts] failed $error');
    }
  };
}

///
/// Read Message Marker
///
/// Send Fully Read or just Read receipts bundled into
/// one http call
ThunkAction<AppState> sendTyping({
  String? roomId,
  bool? typing = false,
}) {
  return (Store<AppState> store) async {
    try {
      // Skip if typing indicators are disabled
      if (!store.state.settingsStore.typingIndicatorsEnabled) {
        log.info('[sendTyping] typing indicators disabled');
        return;
      }

      final data = await MatrixApi.sendTyping(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: roomId,
        userId: store.state.authStore.user.userId,
        typing: typing,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
    } catch (error) {
      log.error('[sendTyping] $error');
    }
  };
}
