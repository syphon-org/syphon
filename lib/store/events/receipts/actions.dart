import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/models.dart';

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
      // Skip if typing indicators are disabled
      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Off) {
        return printInfo('[sendReadReceipts] read receipts disabled');
      }

      if (store.state.settingsStore.readReceipts == ReadReceiptTypes.Hidden) {
        printInfo('[sendReadReceipts] read receipts hidden');
      }

      final data = await MatrixApi.sendReadReceipts(
        protocol: store.state.authStore.protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.user.homeserver,
        roomId: room!.id,
        messageId: message!.id,
        readAll: readAll,
        hidden: store.state.settingsStore.readReceipts == ReadReceiptTypes.Hidden,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      printInfo('[sendReadReceipts] sent ${message.id} $data');
    } catch (error) {
      printInfo('[sendReadReceipts] failed $error');
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
        printInfo('[sendTyping] typing indicators disabled');
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
      printError('[sendTyping] $error');
    }
  };
}
