import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/index.dart';

bool selectIsMedia(Message message) {
  final isBodyNull = message.body == null || message.body!.isEmpty;

  return message.url != null && !isBodyNull;
}

String selectEventBody(Message message) {
  final isBodyEmpty = message.body == null || message.body!.isEmpty;

  // default message conditions
  switch (message.type) {
    case EventTypes.encrypted:
      if (message.typeDecrypted == null && isBodyEmpty) {
        return Strings.labelEncryptedMessage;
      }
      break;
    case EventTypes.message:
      if (isBodyEmpty) {
        return Strings.labelDeletedMessage;
      }
      break;
  }

  // default encrypted message conditions
  if (message.typeDecrypted != null) {
    switch (message.typeDecrypted) {
      case EventTypes.callInvite:
        return Strings.labelCallInvite;

      case EventTypes.callHangup:
        return Strings.labelCallHangup;

      case EventTypes.message:
        if (isBodyEmpty) {
          return Strings.labelDeletedMessage;
        }
        break;
      default:
        return Strings.labelEncryptedMessage;
    }
  }

  return message.body ?? '';
}

// TODO: switch to this when you have more time
String selectEventBodyNew(Message message) {
  final isBodyEmpty = message.body == null || message.body!.isEmpty;

  var messageType = message.type;

  if (message.typeDecrypted != null) {
    messageType = message.typeDecrypted;
  }

  switch (messageType) {
    case EventTypes.encrypted:
      if (isBodyEmpty) {
        return Strings.labelEncryptedMessage;
      }
      break;
    case EventTypes.message:
      // ignore: invariant_booleans
      if (isBodyEmpty) {
        return Strings.labelDeletedMessage;
      }
      break;
    case EventTypes.callInvite:
      return Strings.labelCallInvite;

    case EventTypes.callHangup:
      return Strings.labelCallHangup;

    default:
      if (message.typeDecrypted != null) {
        return Strings.labelEncryptedMessage;
      }
      break;
  }

  return message.body ?? '';
}

// remove messages from blocked users
List<Message> filterMessages(
  List<Message> messages,
  AppState state,
) {
  final blocked = state.userStore.blocked;

  // TODO: remove the replacement filter here, should be managed by the mutators
  return messages
    ..removeWhere(
      (message) =>
          blocked.contains(message.sender) ||
          message.replacement ||
          message.typeDecrypted == EventTypes.callCandidates,
    );
}
