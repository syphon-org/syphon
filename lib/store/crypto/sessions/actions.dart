import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:olm/olm.dart' as olm;
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/keys/selectors.dart';
import 'package:syphon/store/crypto/sessions/converters.dart';
import 'package:syphon/store/crypto/sessions/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';

///
///
/// Key Session Management
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-an-olm-session
/// https://matrix.org/docs/spec/client_server/latest#m-room-key
/// https://matrix.org/docs/spec/client_server/latest#m-olm-v1-curve25519-aes-sha2
/// https://matrix.org/docs/spec/client_server/r0.4.0#m-olm-v1-curve25519-aes-sha2
///
/// Outbound Key Session === Outbound Session (Algorithm.olmv1)
/// Outbound Message Session === Outbound Group Session (Algorithm.megolmv2)
///
/// (Pre)Key Session <--> Only "Session"
/// Message Session <--> prefixed with "Group" Session
///
///
class AddKeySession {
  String session;
  String sessionId;
  String identityKey;

  AddKeySession({
    required this.session,
    required this.sessionId,
    required this.identityKey,
  });
}

class AddMessageSessionOutbound {
  String roomId;
  String session;
  AddMessageSessionOutbound({
    required this.roomId,
    required this.session,
  });
}

class UpdateMessageSessionOutbound {
  String roomId;
  String session;
  int? messageIndex;

  UpdateMessageSessionOutbound({
    required this.roomId,
    required this.session,
    this.messageIndex,
  });
}

class AddMessageSessionInbound {
  String roomId;
  String senderKey;
  String session;
  int messageIndex;
  AddMessageSessionInbound({
    required this.roomId,
    required this.senderKey,
    required this.session,
    required this.messageIndex,
  });
}

class AddMessageSessionsInbound {
  Map<String, Map<String, List<MessageSession>>> sessions;

  AddMessageSessionsInbound({required this.sessions});
}

class SetMessageSessionsInbound {
  Map<String, Map<String, List<MessageSession>>> sessions;

  SetMessageSessionsInbound({required this.sessions});
}

ThunkAction<AppState> saveMessageSessionOutbound({
  required String roomId,
  required String session,
}) {
  return (Store<AppState> store) async {
    store.dispatch(AddMessageSessionOutbound(
      roomId: roomId,
      session: session,
    ));
  };
}

ThunkAction<AppState> exportMessageSession({String? roomId}) {
  return (Store<AppState> store) async {
    final olm.OutboundGroupSession outboundMessageSession = await store.dispatch(
      loadMessageSessionOutbound(roomId: roomId),
    );

    return {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key()
    };
  };
}

ThunkAction<AppState> saveKeySession({
  required String session,
  required String sessionId,
  required String identityKey,
}) {
  return (Store<AppState> store) {
    store.dispatch(AddKeySession(
      session: session,
      sessionId: sessionId,
      identityKey: identityKey,
    ));
  };
}

ThunkAction<AppState> createKeySessionOutbound({
  String? oneTimeKey,
  String? identityKey,
}) {
  return (Store<AppState> store) async {
    final outboundKeySession = olm.Session();

    final account = store.state.cryptoStore.olmAccount!;
    final deviceId = store.state.authStore.user.deviceId!;

    outboundKeySession.create_outbound(account, identityKey!, oneTimeKey!);

    // sychronous
    await store.dispatch(AddKeySession(
      identityKey: identityKey,
      sessionId: outboundKeySession.session_id(),
      session: outboundKeySession.pickle(deviceId),
    ));

    await store.dispatch(saveOlmAccount());
  };
}

ThunkAction<AppState> loadKeySessionOutbound({
  required String identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    try {
      final deviceId = store.state.authStore.user.deviceId!;
      final keySessions = selectKeySessions(store, identityKey);

      printInfo('[loadKeySessionOutbound] checking outbounds for $identityKey');

      for (final session in keySessions.reversed) {
        try {
          // type 1 - attempt to decrypt with an existing sessions
          final keySession = olm.Session()..unpickle(deviceId, session);

          final keySessionId = keySession.session_id();

          final keySessionType = keySession.encrypt_message_type();

          printInfo(
              '[loadKeySessionOutbound] found $keySessionId for $identityKey of type $keySessionType');
          return keySession;
        } catch (error) {
          printInfo('[loadKeySessionOutbound] unsuccessful $identityKey $error');
        }
      }

      throw 'No valid sessions found $identityKey';
    } catch (error) {
      printError('[loadKeySessionOutbound] failure $identityKey $error');
      return null;
    }
  };
}

///
/// Load Key Session Inbound
///
/// Manage and load Olm sessions for pre-key messages or indications
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#molmv1curve25519-aes-sha2
///
ThunkAction<AppState> loadKeySessionInbound({
  required int type,
  required String body,
  required String identityKey, // sender_key
}) {
  return (Store<AppState> store) async {
    final deviceId = store.state.authStore.user.deviceId!;

    // filter all key session saved under a certain identityKey
    final keySessions = selectKeySessions(store, identityKey);

    printInfo('[loadKeySessionInbound] checking known sessions for sender $identityKey');

    // reverse the list to attempt the latest first (LinkedHashMap will know)
    for (final session in keySessions.reversed) {
      try {
        // attempt to decrypt with any existing sessions
        final keySession = olm.Session()..unpickle(deviceId, session);
        final keySessionId = keySession.session_id();

        // this returns a flag indicating whether the message was encrypted using that session
        final keySessionMatch = keySession.matches_inbound(body);

        printInfo('[loadKeySessionInbound] $keySessionId session matched $keySessionMatch');

        if (keySessionMatch) {
          return keySession;
        }

        printInfo('[loadKeySessionInbound] $keySessionId attempting decryption');

        // attempt decryption in case its not a locally known inbound session state
        keySession.decrypt(type, body);

        printInfo('[loadKeySessionInbound] $keySessionId successfully decrypted');

        // Return a fresh key session having not decrypted the payload
        return olm.Session()..unpickle(deviceId, session);
      } catch (error) {
        printError('[loadKeySessionInbound] unsuccessful $error');
      }
    }

    try {
      // if type zero, and no other known sessions can decrypt, create a new one
      if (type == 0) {
        final newKeySession = olm.Session();
        final account = store.state.cryptoStore.olmAccount!;

        // Call olm_create_inbound_session_from using the olm account, and the sender_key and body of the message.
        newKeySession.create_inbound_from(account, identityKey, body);

        // that the same one-time-key from the sender cannot be reused.
        account.remove_one_time_keys(newKeySession);

        // Save sessions as needed
        await store.dispatch(saveOlmAccount());
        await store.dispatch(saveKeySession(
          identityKey: identityKey,
          sessionId: newKeySession.session_id(),
          session: newKeySession.pickle(deviceId),
        ));

        // Return new key session
        return newKeySession;
      }
    } catch (error) {
      printError('[loadKeySessionInbound] $error');
    }

    return null;
  };
}

/// Inbound Message Session
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
ThunkAction<AppState> createMessageSessionInbound({
  required String roomId,
  required String senderKey,
  required String sessionKey,
}) {
  return (Store<AppState> store) async {
    final inboundMessageSession = olm.InboundGroupSession();

    inboundMessageSession.create(sessionKey);
    final messageIndex = inboundMessageSession.first_known_index();

    await store.dispatch(AddMessageSessionInbound(
      roomId: roomId,
      senderKey: senderKey,
      messageIndex: messageIndex,
      session: inboundMessageSession.pickle(roomId),
    ));
  };
}

ThunkAction<AppState> loadMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required String ciphertext,
}) {
  return (Store<AppState> store) async {
    final roomMessageSessions = store.state.cryptoStore.messageSessionsInbound[roomId];

    if (roomMessageSessions == null || !roomMessageSessions.containsKey(identityKey)) {
      throw 'Unable to find inbound message session for decryption';
    }

    // TODO: add sorting after testing current impl
    final messageSessions = roomMessageSessions[identityKey]!;

    for (final messageSession in messageSessions) {
      try {
        // test decrypting with the inbound group session
        final testSession = olm.InboundGroupSession();
        testSession.unpickle(roomId, messageSession.serialized);
        testSession.decrypt(ciphertext);

        return messageSession;
      } catch (error) {
        log.warn('[loadMessageSessionInbound] valid session could not decrypt message');
      }
    }

    throw 'Unable to find inbound message session for decryption';
  };
}

///
/// Save Message Session Inbound
///
/// Saves the message session and index after encrypting and sending an event
ThunkAction<AppState> saveMessageSessionInbound({
  required String roomId,
  required String identityKey,
  required olm.InboundGroupSession session,
  required int messageIndex,
}) {
  return (Store<AppState> store) async {
    return await store.dispatch(AddMessageSessionInbound(
      roomId: roomId,
      senderKey: identityKey,
      session: session.pickle(roomId),
      messageIndex: messageIndex,
    ));
  };
}

///
/// Outbound Message Session Functionality
///
/// https://matrix.org/docs/guides/end-to-end-encryption-implementation-guide#starting-a-megolm-session
ThunkAction<AppState> createMessageSessionOutbound({required String roomId}) {
  return (Store<AppState> store) async {
    // Get current user device identity key
    final deviceId = store.state.authStore.user.deviceId;
    final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;

    final currentDeviceKey = deviceKeysOwned[deviceId!]!;

    final identityKeyId = Keys.identityKeyId(deviceId: deviceId);

    final identityKey = currentDeviceKey.keys![identityKeyId];

    if (identityKey == null) {
      throw 'Failed to extract identityKey for this session';
    }

    final outboundMessageSession = olm.OutboundGroupSession();
    final inboundMessageSession = olm.InboundGroupSession();

    outboundMessageSession.create();
    final session = {
      'session_id': outboundMessageSession.session_id(),
      'session_key': outboundMessageSession.session_key(),
    };

    inboundMessageSession.create(session['session_key']!);

    store.dispatch(AddMessageSessionOutbound(
      roomId: roomId,
      session: outboundMessageSession.pickle(roomId),
    ));

    store.dispatch(AddMessageSessionInbound(
      roomId: roomId,
      senderKey: identityKey,
      session: inboundMessageSession.pickle(roomId),
      messageIndex: inboundMessageSession.first_known_index(),
    ));

    // send back a serialized version
    return outboundMessageSession.pickle(roomId);
  };
}

///
/// Load Message Session Outbound
///
/// TODO: potentially convert to identity + device similar to inbound
///
ThunkAction<AppState> loadMessageSessionOutbound({String? roomId}) {
  return (Store<AppState> store) async {
    // Load session for identity
    var outboundMessageSessionSerialized = store.state.cryptoStore.outboundMessageSessions[roomId!];

    if (outboundMessageSessionSerialized == null) {
      outboundMessageSessionSerialized = await store.dispatch(
        createMessageSessionOutbound(roomId: roomId),
      );
    }

    final messageSession = olm.OutboundGroupSession();
    messageSession.unpickle(roomId, outboundMessageSessionSerialized!);
    return messageSession;
  };
}

ThunkAction<AppState> exportSessionKeys(String password) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      // create file
      var directory = await getApplicationDocumentsDirectory();
      var confirmation = 'Successfully backed up your current session keys';

      if (Platform.isAndroid) {
        directory = Directory(Values.ANDROID_DEFAULT_DIRECTORY);
        confirmation += ' to Documents folder';
      }

      if (Platform.isIOS) {
        confirmation += ' to ${directory.path}';
      }

      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        final directoryPath = await FilePicker.platform.saveFile(
          type: FileType.custom,
          allowedExtensions: ['txt'],
        );

        if (directoryPath == null) {
          return store.dispatch(addAlert(
            origin: 'exportSessionKeys',
            message: 'A path is required to save a session key backup file.',
          ));
        }

        directory = Directory(directoryPath);

        confirmation += ' to $directoryPath';
      }

      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final messageSessions = store.state.cryptoStore.messageSessionsInbound;

      final deviceKeysByDeviceId = deviceKeys.values.toList().fold<Map<String, DeviceKey>>(
          <String, DeviceKey>{}, (previous, current) => previous..addAll(current));

      final deviceKeyIdentities = Map.fromIterable(
        deviceKeysByDeviceId.values,
        key: (device) => (device as DeviceKey).curve25519,
        value: (device) => (device as DeviceKey).ed25519,
      );

      final sessionData = [];

      // prepend session keys to an array per spec
      for (final roomSessions in messageSessions.entries) {
        final roomId = roomSessions.key;
        final sessions = roomSessions.value;

        for (final messsageSessions in sessions.entries) {
          final identityKey = messsageSessions.key;
          final sessionsSerialized = messsageSessions.value;
          final deviceKeyEd25519 = deviceKeyIdentities[identityKey];

          for (final session in sessionsSerialized) {
            final messageIndex = session.index;

            // attempt to decrypt with any existing sessions
            final inboundSession = olm.InboundGroupSession()..unpickle(roomId, session.serialized);

            // session
            final sessionId = inboundSession.session_id();
            final sessionKey = inboundSession.export_session(messageIndex);

            sessionData.add({
              'algorithm': Algorithms.megolmv1,
              // TODO: support needed alongside m.forwarded_room_key events.
              'forwarding_curve25519_key_chain': [],
              'room_id': roomId,
              'sender_key': identityKey,
              'sender_claimed_keys': {
                'ed25519': deviceKeyEd25519,
              },
              'session_id': sessionId,
              'session_key': sessionKey,
            });
          }
        }
      }

      // for debugging only
      // if (DEBUG_MODE) {
      //   log.json({
      //     'sessionData': sessionData,
      //   });
      // }

      // encrypt exported session keys
      final String encryptedExport = await compute(encryptSessionKeysThreaded, {
        'sessionJson': sessionData,
        'password': password,
      });

      final currentTime = DateTime.now();
      final formattedTime = DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();
      final fileName = '${Values.appName}_key_backup_$formattedTime.txt'.toLowerCase();

      final file = File('${directory.path}/$fileName');

      await file.writeAsString(encryptedExport);

      store.dispatch(addConfirmation(
        origin: 'exportSessionKeys',
        message: confirmation,
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'exportSessionKeys',
        message:
            'Failed to backup your current session keys, contact us at https://syphon.org/support',
      ));
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}

///
/// Import Session Keys
///
/// Responsible for decrypting the key import file and setting
/// the resulting session to storage.
///
ThunkAction<AppState> importSessionKeys(FilePickerResult file, {String? password}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoadingSettings(loading: true));

      final keyFile = File(file.paths[0]!);
      final fileData = await keyFile.readAsString();

      var sessionJson;

      if (password == null || password.isEmpty) {
        sessionJson = json.decode(utf8.decode(keyFile.readAsBytesSync()));
      } else {
        sessionJson = await compute(
          decryptSessionKeysThreaded,
          {'fileData': fileData, 'password': password},
        );
      }

      final roomIdsEncrypted = [];
      final messageSessions = Map<String, Map<String, List<MessageSession>>>.from(
        store.state.cryptoStore.messageSessionsInbound,
      );

      for (final session in sessionJson) {
        final roomId = session['room_id'] as String;
        final senderKey = session['sender_key'] as String;
        final sessionKey = session['session_key'] as String;

        final inboundSession = olm.InboundGroupSession()..import_session(sessionKey);
        final sessionIndexNew = inboundSession.first_known_index();

        // for debugging only
        // if (DEBUG_MODE) {
        //   final sessionIdNew = inboundSession.session_id();

        //   log.json({
        //     'sessionIdNew': sessionIdNew,
        //     'sessionIndexNew': sessionIndexNew,
        //   });
        // }

        final messageSession = MessageSession(
          index: sessionIndexNew,
          serialized: inboundSession.pickle(roomId),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );

        messageSessions.update(
          roomId,
          (sessions) => sessions
            ..update(
              senderKey,
              (value) => value..insert(0, messageSession),
              ifAbsent: () => [messageSession],
            ),
          ifAbsent: () => {
            senderKey: [messageSession],
          },
        );

        roomIdsEncrypted.add(roomId);
      }

      await store.dispatch(SetMessageSessionsInbound(
        sessions: combineMessageSesssions(
          messageSessions,
          store.state.cryptoStore.messageSessionsInbound,
        ),
      ));

      for (final roomId in roomIdsEncrypted) {
        store.dispatch(backfillDecryptMessages(roomId));
      }

      store.dispatch(addConfirmation(
        origin: 'importSessionKeys',
        message: 'Successfully imported keys, your previous messages should be decrypting.',
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'importSessionKeys',
        message:
            'Failed to import your session key backup, contact us at https://syphon.org/support',
      ));
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}
