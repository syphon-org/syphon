import 'dart:convert';

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

// responsibile for json serialization and encryption
Future<String> serializeJsonBackground(Object store) async {
  try {
    Stopwatch stopwatch = new Stopwatch()..start();

    final ivKey = await unlockIVKey();
    final cryptKey = await unlockCryptKey();
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
