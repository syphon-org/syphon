import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

const DEFAULT_ROUNDS = 500000;

Uint8List convertIntToBytes(int value) =>
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.big);

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

Map<String, Map<String, List<MessageSession>>> combineMessageSesssions(sessionNew, sessionOld) {
  final messageSessionsNew = sessionNew as Map<String, Map<String, List<MessageSession>>>;

  final messageSessionsOld = Map<String, Map<String, List<MessageSession>>>.from(
    sessionOld,
  );

  // prepend session keys to an array per spec
  for (final roomSessions in messageSessionsNew.entries) {
    final roomId = roomSessions.key;
    final sessions = roomSessions.value;

    for (final messsageSessions in sessions.entries) {
      final senderKey = messsageSessions.key;
      final sessionsSerialized = messsageSessions.value;

      for (final session in sessionsSerialized) {
        messageSessionsOld.update(
          roomId,
          (identitySessions) => identitySessions
            ..update(
              senderKey,
              (sessions) => sessions.toList()..insert(0, session),
              ifAbsent: () => [session],
            ),
          ifAbsent: () => {
            senderKey: [session],
          },
        );
      }
    }
  }

  return messageSessionsOld;
}
