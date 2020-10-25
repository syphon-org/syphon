import 'dart:convert';

import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/cache/index.dart';

// NOTE: deserialization is required synchronous by redux_persist :/
Future<String> decryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String cryptKey = params['cryptKey'];
  String json = params['json'];

  final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);

  final decryptedJson = cryptor.ctr.decrypt(enc: json, iv: ivKey);

  return jsonDecode(decryptedJson);
}

Future<String> encryptJsonBackground(Map params) async {
  String ivKey = params['ivKey'];
  String cryptKey = params['cryptKey'];
  String json = params['json'];
  String type = params['type'];

  Stopwatch stopwatch = new Stopwatch()..start();

  final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);
  final encryptedJson = cryptor.ctr.encrypt(inp: json, iv: ivKey);

  final stopwatchTime = stopwatch.elapsed;

  print('[encryptJsonBackground] ${type} $stopwatchTime');

  return encryptedJson;
}

// responsibile for both json serialization and encryption
Future<String> serializeJsonBackground(Object store) async {
  WidgetsFlutterBinding.ensureInitialized();
  window.onPlatformMessage = BinaryMessages.handlePlatformMessage;

  try {
    Stopwatch stopwatch = new Stopwatch()..start();

    final storageEngine = FlutterSecureStorage();

    final ivKey = await storageEngine.read(key: CacheSecure.ivKeyLocation);
    final cryptKey =
        await storageEngine.read(key: CacheSecure.encryptionKeyLocation);

    final jsonEncoded = jsonEncode(store);

    final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);
    final jsonEncrypted = cryptor.ctr.encrypt(inp: jsonEncoded, iv: ivKey);

    print(
      '[serializeJsonBackground] ${store.runtimeType.toString()} ${stopwatch.elapsed}',
    );
    return jsonEncrypted;
  } catch (error) {
    print(
      '[serializeJsonBackground] ${store.runtimeType.toString()} ${error}',
    );
    return null;
  }
}
