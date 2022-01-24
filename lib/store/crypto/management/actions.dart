import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:olm/olm.dart' as olm;
import 'package:path_provider/path_provider.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';

class SetInboundMessageSessions {
  Map<String, Map<String, String>> sessions;

  SetInboundMessageSessions({
    required this.sessions,
  });
}

const DEFAULT_ROUNDS = 500000;

///
/// Encrypt Session Keys
///
/// Responsible for decrypting the key import file as well
/// Below is a block table for the encrypted data
///
/// - 1 	Export format version, which must be 0x01.
/// - 16 	The salt S.
/// - 16 	The initialization vector IV.
/// - 4 	The number of rounds N, as a big-endian unsigned 32-bit integer.
/// - variable 	The encrypted JSON object.
/// - 32 	The HMAC-SHA-256 of all the above string concatenated together, using K' as the key.
///
Future<String> encryptSessionKeys({
  required List<dynamic> sessionJson,
  String? password,
}) async {
  try {
    if (password == null || password.isEmpty) {
      throw 'Must have a password for encrypting a file';
    }

    final sessionString = json.encode(sessionJson);

    const iv = 'TODO:';
    const salt = 'TODO:';

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: DEFAULT_ROUNDS,
      bits: 512,
    );

    final encryptionKeySecret = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt.codeUnits,
    );

    final ivFormatted = base64.encode(iv.codeUnits);
    final encryptedJsonFormatted = base64.encode(sessionString.codeUnits);

    final allKeys = await encryptionKeySecret.extractBytes();

    // NOTE: split on 256 offset, for K and K'
    final encryptionKey = base64.encode(
      allKeys.sublist(0, 32),
    );

    final codec = encrypt.AES(
      encrypt.Key.fromBase64(encryptionKey),
      mode: encrypt.AESMode.ctr,
      padding: null,
    );

    final data = codec.encrypt(
      Uint8List.fromList(encryptedJsonFormatted.codeUnits),
      iv: encrypt.IV.fromBase64(ivFormatted),
    );

    // final dataEnd = keyFileBytes.length - 32;

    // final version = keyFileBytes.sublist(0, 1);
    // final keySha = keyFileBytes.sublist(dataEnd, keyFileBytes.length);

    // // needed for decryption
    // final salt = keyFileBytes.sublist(1, 17);
    // final iv = keyFileBytes.sublist(17, 33);
    // final rounds = keyFileBytes.sublist(33, 37);
    // final encryptedJson = keyFileBytes.sublist(37, dataEnd);

    return '''
       ${Values.SESSION_EXPORT_HEADER}
       ${data.base64}
       ${Values.SESSION_EXPORT_FOOTER}
    '''
        .trim();
  } catch (error) {
    rethrow;
  }
}

///
/// Decrypt Session Keys
///
/// Responsible for decrypting the key import file as well
/// Below is a block table for the encrypted data
///
/// - 1 	Export format version, which must be 0x01.
/// - 16 	The salt S.
/// - 16 	The initialization vector IV.
/// - 4 	The number of rounds N, as a big-endian unsigned 32-bit integer.
/// - variable 	The encrypted JSON object.
/// - 32 	The HMAC-SHA-256 of all the above string concatenated together, using K' as the key.
///
Future<List<dynamic>> decryptSessionKeys(
  FilePickerResult file, {
  String? password,
}) async {
  try {
    final keyFile = File(file.paths[0]!);
    final keyFileDataHeaded = await keyFile.readAsString();

    if (password == null || password.isEmpty) {
      return json.decode(utf8.decode(keyFile.readAsBytesSync()));
    }

    final keyFileString = keyFileDataHeaded
        .replaceAll(Values.SESSION_EXPORT_HEADER, '')
        .replaceAll(Values.SESSION_EXPORT_FOOTER, '')
        .replaceAll('\n', '')
        .trim();

    final keyFileBytes = base64.decode(keyFileString);

    final dataEnd = keyFileBytes.length - 32;

    final version = keyFileBytes.sublist(0, 1);
    final keySha = keyFileBytes.sublist(dataEnd, keyFileBytes.length);

    // needed for decryption
    final salt = keyFileBytes.sublist(1, 17);
    final iv = keyFileBytes.sublist(17, 33);
    final rounds = keyFileBytes.sublist(33, 37);
    final encryptedJson = keyFileBytes.sublist(37, dataEnd);

    final ivFormatted = base64.encode(iv);
    final encryptedJsonFormatted = base64.encode(encryptedJson);
    final roundsFormatted = ByteData.view(
      Uint8List.fromList(rounds.toList()).buffer,
    ).getUint32(0, Endian.big);

    // Uncomment
    // printJson({
    //   'version': version,
    //   'salt': base64.encode(salt),
    //   'iv': ivFormatted,
    //   'rounds': roundsFormatted,
    //   'keySha': base64.encode(keySha),
    // });

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: roundsFormatted,
      bits: 512,
    );

    final encryptionKeySecret = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final allKeys = await encryptionKeySecret.extractBytes();

    // NOTE: split on 256 offset, for K and K'
    final encryptionKey = base64.encode(
      allKeys.sublist(0, 32),
    );

    final codec = encrypt.AES(
      encrypt.Key.fromBase64(encryptionKey),
      mode: encrypt.AESMode.ctr,
      padding: null,
    );

    final data = codec.decrypt(
      encrypt.Encrypted.fromBase64(encryptedJsonFormatted),
      iv: encrypt.IV.fromBase64(ivFormatted),
    );

    return json.decode(utf8.decode(data));
  } catch (error) {
    rethrow;
  }
}

ThunkAction<AppState> exportSessionKeys(String password) {
  return (Store<AppState> store) async {
    try {
      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final messageSessions = store.state.cryptoStore.inboundMessageSessions;

      final deviceKeysByDeviceId = deviceKeys.values.toList().fold<Map<String, DeviceKey>>(
          <String, DeviceKey>{}, (previous, current) => previous..addAll(current));
      final sessionData = [];

      // prepend session keys to an array per spec
      for (final roomSession in messageSessions.entries) {
        final roomId = roomSession.key;
        final sessions = roomSession.value;
        final roomMessageIndexs = store.state.cryptoStore.messageSessionIndex[roomId];

        for (final session in sessions.entries) {
          final identityKey = session.key;
          final sessionSerialized = session.value;
          final identityMessageIndex = roomMessageIndexs?[identityKey] ?? -1;
          final deviceKey = deviceKeysByDeviceId[identityKey] ?? DeviceKey();

          // attempt to decrypt with any existing sessions
          final inboundSession = olm.InboundGroupSession()..unpickle(roomId, sessionSerialized);

          // session
          final sessionId = inboundSession.session_id();
          final sessionKey = inboundSession.export_session(identityMessageIndex);

          sessionData.add({
            'algorithm': Algorithms.megolmv1,
            'forwarding_curve25519_key_chain': [], // TODO:
            'room_id': roomId,
            'sender_key': identityKey,
            'sender_claimed_keys': {
              // TODO: confirm is the correct ed25519 key
              'ed25519': (deviceKey.keys ?? {})[Algorithms.ed25519],
            },
            'session_id': sessionId,
            'session_key': sessionKey,
          });
        }
      }

      // encrypt exported session keys
      final String encryptedExport = await encryptSessionKeys(
        sessionJson: sessionData,
        password: password,
      );

      // create file
      final directory = await getApplicationDocumentsDirectory();

      final currentTime = DateTime.now();
      final formattedTime = DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();

      final fileName = '${directory.path}/${Values.appName}_export_$formattedTime.txt';
      final file = File(fileName);

      await file.writeAsString(encryptedExport);
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'exportSessionKeys',
      ));
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
      // decrypt imported session key file if necessary
      printDebug('[importSessionKeys] decrypting file');

      final sessionJson = await decryptSessionKeys(file, password: password);

      final roomIdsEncrypted = [];
      final messageSessions = Map<String, Map<String, String>>.from(
        store.state.cryptoStore.inboundMessageSessions,
      );

      for (final session in sessionJson) {
        final roomId = session['room_id'] as String;
        final senderKey = session['sender_key'] as String;
        final sessionKey = session['session_key'] as String;

        final inboundSession = olm.InboundGroupSession()..import_session(sessionKey);

        final sessionIdNew = inboundSession.session_id();
        final sessionIndexNew = inboundSession.first_known_index();

        messageSessions.update(
          roomId,
          (sessions) => sessions
            ..update(
              senderKey,
              (value) => inboundSession.pickle(roomId),
              ifAbsent: () => inboundSession.pickle(roomId),
            ),
          ifAbsent: () => {
            senderKey: inboundSession.pickle(roomId),
          },
        );

        roomIdsEncrypted.add(roomId);
      }

      store.dispatch(SetInboundMessageSessions(
        sessions: messageSessions,
      ));

      for (final roomId in roomIdsEncrypted) {
        store.dispatch(backfillDecryptMessages(roomId));
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'importSessionKeys',
      ));
    }
  };
}
