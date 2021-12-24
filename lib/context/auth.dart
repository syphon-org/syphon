import 'dart:convert';

import 'package:crypto/crypto.dart' as crypt;
import 'package:cryptography/cryptography.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' as io;
import 'package:syphon/context/types.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/print.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
String generateContextId() {
  final shaHash = crypt.sha256.convert(utf8.encode(getRandomString(10)));
  return base64
      .encode(shaHash.bytes)
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w]'), '')
      .substring(0, 10);
}

// Switch to generating UserID independent context IDs that can still be managed globally
// ignore: non_constant_identifier_names
String generateContextId_DEPRECATED({required String id}) {
  final shaHash = crypt.sha256.convert(utf8.encode(id));
  return base64
      .encode(shaHash.bytes)
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w]'), '')
      .substring(0, 10);
}

Future<String> generatePinHash({required String passcode, String salt = 'TODO:'}) async {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 25000,
    bits: 128,
  );

  // Password we want to hash
  final secretKey = SecretKey(utf8.encode(passcode));

  // A random salt
  final nonce = utf8.encode(salt); // TODO: add salt, tos timestamp?

  // Calculate a hash that can be stored in the database
  final newSecretKey = await pbkdf2.deriveKey(
    secretKey: secretKey,
    nonce: nonce,
  );

  return base64.encode(await newSecretKey.extractBytes());
}

Future<bool> generatePinHashWrapper(Map params) async {
  final String hash = params['hash'] ?? '';
  final String passcode = params['passcode'] ?? '';

  return await generatePinHash(passcode: passcode) == hash;
}

Future<bool> verifyPinHashIsolate({required String passcode, required String hash}) async {
  final Map params = {
    'passcode': passcode,
    'hash': hash,
  };

  return io.compute(generatePinHashWrapper, params);
}

Future<bool> verifyPinHash({required String passcode, required String hash}) async {
  return await generatePinHash(passcode: passcode) == hash;
}

Key convertPasscodeToKey(String passcode) {
  return Key.fromBase64(passcode.padRight(32, passcode[0]));
}

Future<String> unlockSecretKey(AppContext context, String passcode) async {
  final iv = IV.fromBase64(context.id.substring(0, 8));
  final encrypter = Encrypter(AES(convertPasscodeToKey(passcode), mode: AESMode.sic));

  printInfo('[unlockSecretKey] $passcode, ${context.secretKeyEncrypted}, ${context.id}');

  // ignore: await_only_futures
  return encrypter.decrypt(Encrypted.fromBase64(context.secretKeyEncrypted), iv: iv);
}

Future<String> convertSecretKey(AppContext context, String passcode, String plaintextKey) async {
  final iv = IV.fromBase64(context.id.substring(0, 8));
  final encrypter = Encrypter(AES(convertPasscodeToKey(passcode), mode: AESMode.sic));

  printInfo('[convertSecretKey] $passcode, $plaintextKey, ${context.id}');

  // ignore: await_only_futures
  return await encrypter.encrypt(plaintextKey, iv: iv).base64;
}
