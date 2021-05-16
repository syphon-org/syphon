import 'dart:convert';
import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/print.dart';

Future<String> encryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String cryptKey = params['cryptKey'];
  String json = params['json'];

  final iv = IV.fromBase64(ivKey);
  final key = Key.fromBase64(cryptKey);

  final encrypter = Encrypter(AES(key, mode: AESMode.ctr, padding: null));
  final encrypted = encrypter.encrypt(json, iv: iv);

  return encrypted.base64;
}

Future<Map?> decryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String ivKeyNext = params['ivKeyNext'];
  String? type = params['type'];
  String cryptKey = params['cryptKey'];
  String? jsonEncrypted = params['json'];

  String? jsonDecrypted;
  Map<String, dynamic>? jsonDecoded = {};

  final iv = IV.fromBase64(ivKey);
  final ivNext = IV.fromBase64(ivKeyNext);
  final key = Key.fromBase64(cryptKey);

  final encrypter = Encrypter(AES(key, mode: AESMode.ctr, padding: null));

  if (jsonEncrypted == null) return null;

  try {
    jsonDecrypted = encrypter.decrypt64(
      jsonEncrypted,
      iv: iv,
    );
  } catch (error) {
    printDebug('[decryptJsonBackground] error $error');
  }

  if (jsonDecoded.isEmpty) {
    try {
      jsonDecrypted = encrypter.decrypt64(
        jsonEncrypted,
        iv: ivNext,
      );
    } catch (error) {
      printDebug('[decryptJsonBackground] error $error');
      jsonDecoded = {};
    }
  }

  // Failed to decrypt data
  if (jsonDecrypted == null) {
    printDebug('[decryptJsonBackground] decryption failed ${type}');
    return null;
  }

  // decode serialized object
  jsonDecoded = json.decode(jsonDecrypted);

  printDebug('[decryptJsonBackground] decryption succeed ${type}');
  return jsonDecoded;
}

// responsibile for both json serialization and encryption
Future<String?> serializeJsonBackground(Object store) async {
  try {
    final storageEngine = FlutterSecureStorage();

    final ivKey = await storageEngine.read(key: Cache.ivLocation);
    final cryptKey = await storageEngine.read(key: Cache.keyLocation);

    final iv = IV.fromBase64(ivKey!);
    final key = Key.fromBase64(cryptKey!);

    final jsonEncoded = jsonEncode(store);

    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    final encrypted = encrypter.encrypt(jsonEncoded, iv: iv);

    return encrypted.base64;
  } catch (error) {
    printError('[serializeJsonBackground] $error');
    return null;
  }
}
