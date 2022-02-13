import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
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
import 'package:syphon/store/crypto/events/actions.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';

class SetInboundMessageSessions {
  Map<String, Map<String, String>> sessions;

  SetInboundMessageSessions({
    required this.sessions,
  });
}

const DEFAULT_ROUNDS = 500000;

Uint8List convertIntToBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

///
/// Encrypt Session Keys (Threaded)
///
/// Responsible for decrypting the key import file as well
/// Below is a block table for the encrypted data
///
/// Allows encrypting off the main thread
///
Future<String> encryptSessionKeysThreaded(Map params) async {
  final List<dynamic> sessionJson = params['sessionJson'] as List<dynamic>;
  final String? password = params['password'];

  return encryptSessionKeys(
    sessionJson: sessionJson,
    password: password,
  );
}

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

    final iv = encrypt.SecureRandom(16);
    final salt = encrypt.SecureRandom(16);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: DEFAULT_ROUNDS,
      bits: 512,
    );

    final encryptionKeySecret = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt.bytes,
    );

    final encryptionKeys = await encryptionKeySecret.extractBytes();

    final sessionJsonFormatted = utf8.encode(sessionString);

    // NOTE: split on 256 offset, for K and K'
    final encryptionKey = base64.encode(
      encryptionKeys.sublist(0, 32),
    );

    final codec = encrypt.AES(
      encrypt.Key.fromBase64(encryptionKey),
      mode: encrypt.AESMode.ctr,
      padding: null,
    );

    final sessionData = codec.encrypt(
      Uint8List.fromList(sessionJsonFormatted),
      iv: encrypt.IV.fromBase64(iv.base64),
    );

    final byteBuilder = BytesBuilder();

    byteBuilder.addByte(1); // version
    byteBuilder.add(salt.bytes);
    byteBuilder.add(iv.bytes);
    byteBuilder.add(convertIntToBytes(DEFAULT_ROUNDS));
    byteBuilder.add(sessionData.bytes); // actual session data

    final hmacSha256 = crypto.Hmac(crypto.sha256, encryptionKeys.sublist(32, 64));
    final digest = hmacSha256.convert(byteBuilder.toBytes());

    byteBuilder.add(digest.bytes); // HMAC-SHA-256 of all of the above together using k'

    // Uncomment for testing
    // printJson({
    //   'version': 1,
    //   'salt': base64.encode(salt.bytes),
    //   'iv': base64.encode(iv.bytes),
    //   'rounds': base64.encode(convertIntToBytes(DEFAULT_ROUNDS)),
    //   'keySha': base64.encode(crypto.sha256.convert(encryptionKeys).bytes),
    // });

    return '''${Values.SESSION_EXPORT_HEADER}\n${base64.encode(byteBuilder.toBytes())}\n${Values.SESSION_EXPORT_FOOTER}'''
        .trim();
  } catch (error) {
    rethrow;
  }
}

///
/// Decrypt Session Keys (Threaded)
///
/// Responsible for decrypting the key import file as well
/// Below is a block table for the encrypted data
///
/// Allows running decryption in a background thread
///
Future<List<dynamic>> decryptSessionKeysThreaded(Map params) async {
  final String? fileData = params['fileData'];
  final String? password = params['password'];
  final String? override = params['override'];

  return decryptSessionKeys(
    fileData: fileData!,
    password: password!,
    override: override,
  );
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
Future<List<dynamic>> decryptSessionKeys({
  required String fileData,
  required String password,
  String? override,
}) async {
  try {
    final keyFileString = fileData
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

    // for debugging only
    if (DEBUG_MODE) {
      printJson({
        'version': version,
        'salt': base64.encode(salt),
        'iv': ivFormatted,
        'rounds': roundsFormatted,
        'keySha': base64.encode(keySha),
      });
    }

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
      store.dispatch(SetLoadingSettings(loading: true));

      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final messageSessions = store.state.cryptoStore.inboundMessageSessions;

      final deviceKeysByDeviceId = deviceKeys.values.toList().fold<Map<String, DeviceKey>>(
          <String, DeviceKey>{}, (previous, current) => previous..addAll(current));

      final deviceKeyIdentities = Map.fromIterable(
        deviceKeysByDeviceId.values,
        key: (device) => (device as DeviceKey).curve25519,
        value: (device) => (device as DeviceKey).ed25519,
      );

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
          final deviceKeyEd25519 = deviceKeyIdentities[identityKey];

          // attempt to decrypt with any existing sessions
          final inboundSession = olm.InboundGroupSession()..unpickle(roomId, sessionSerialized);

          // session
          final sessionId = inboundSession.session_id();
          final sessionKey = inboundSession.export_session(identityMessageIndex);

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

      // for debugging only
      if (DEBUG_MODE) {
        printJson({
          'sessionData': sessionData,
        });
      }

      // encrypt exported session keys
      final String encryptedExport = await compute(encryptSessionKeysThreaded, {
        'sessionJson': sessionData,
        'password': password,
      });

      // create file
      var directory = await getApplicationDocumentsDirectory();

      if (Platform.isAndroid) {
        directory =
            ((await getExternalStorageDirectories(type: StorageDirectory.documents)) ?? []).first;

        print('IS ANDROID ${directory.path}');

        directory = Directory('/storage/emulated/0/Documents');

        print('IS ANDROID ${directory.path}');
      }

      final currentTime = DateTime.now();
      final formattedTime = DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();
      final fileName = '${Values.appName}_key_backup_$formattedTime.txt'.toLowerCase();

      final file = File('${directory.path}/$fileName');

      await file.writeAsString(encryptedExport);

      store.dispatch(addConfirmation(
        origin: 'exportSessionKeys',
        message: 'Successfully backed up your current session keys',
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'exportSessionKeys',
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
      final messageSessions = Map<String, Map<String, String>>.from(
        store.state.cryptoStore.inboundMessageSessions,
      );

      for (final session in sessionJson) {
        final roomId = session['room_id'] as String;
        final senderKey = session['sender_key'] as String;
        final sessionKey = session['session_key'] as String;

        final inboundSession = olm.InboundGroupSession()..import_session(sessionKey);

        // for debugging only
        if (DEBUG_MODE) {
          final sessionIdNew = inboundSession.session_id();
          final sessionIndexNew = inboundSession.first_known_index();

          printJson({
            'sessionIdNew': sessionIdNew,
            'sessionIndexNew': sessionIndexNew,
          });
        }

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

      store.dispatch(addConfirmation(
        origin: 'importSessionKeys',
        message: 'Successfully imported keys, your previous messages should be decrypting.',
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'importSessionKeys',
      ));
    } finally {
      store.dispatch(SetLoadingSettings(loading: false));
    }
  };
}
