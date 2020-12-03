import 'dart:convert';

import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/cache/index.dart';

Future<String> encryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String cryptKey = params['cryptKey'];
  String json = params['json'];

  final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);

  return cryptor.ctr.encrypt(inp: json, iv: ivKey);
}

Future<Map> decryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String ivKeyNext = params['ivKeyNext'];
  String type = params['type'];
  String cryptKey = params['cryptKey'];
  String jsonEncrypted = params['json'];

  String jsonDecrypted;
  Map<String, dynamic> jsonDecoded = {};

  final aes = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);

  if (jsonEncrypted == null) return null;

  try {
    jsonDecrypted = aes.ctr.decrypt(
      enc: jsonEncrypted,
      iv: ivKey,
    );
  } catch (error) {
    debugPrint('[decryptJsonBackground] error $error');
  }

  if (jsonDecoded.isEmpty) {
    try {
      jsonDecrypted = aes.ctr.decrypt(
        enc: jsonEncrypted,
        iv: ivKeyNext,
      );
    } catch (error) {
      debugPrint('[decryptJsonBackground] error $error');
      jsonDecoded = {};
    }
  }

  // Failed to decrypt data
  if (jsonDecrypted == null) {
    debugPrint('[decryptJsonBackground] decryption failed ${type}');
    return null;
  }

  // decode serialized object
  jsonDecoded = json.decode(jsonDecrypted);

  debugPrint('[decryptJsonBackground] decryption succeed ${type}');
  return jsonDecoded;
}

// TODO: needs plugins that work in isolates, still having
// issues using path_provider or any equivalent in threads
// while still being able to pass the entire store object
// to the isolate
// responsibile for both json serialization and encryption
Future<String> serializeJsonBackground(Object store) async {
  WidgetsFlutterBinding.ensureInitialized();
  window.onPlatformMessage = BinaryMessages.handlePlatformMessage;

  try {
    final storageEngine = FlutterSecureStorage();

    final ivKey = await storageEngine.read(key: CacheSecure.ivKeyLocation);
    final cryptKey =
        await storageEngine.read(key: CacheSecure.cryptKeyLocation);

    final jsonEncoded = jsonEncode(store);

    final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);

    return cryptor.ctr.encrypt(inp: jsonEncoded, iv: ivKey);
  } catch (error) {
    debugPrint('[serializeJsonBackground] $error');
    return null;
  }
}
