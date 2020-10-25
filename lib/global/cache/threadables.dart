import 'dart:convert';

import 'package:steel_crypt/steel_crypt.dart';

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

  Stopwatch stopwatchTwo = new Stopwatch()..start();

  final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);
  final encryptedJson = cryptor.ctr.encrypt(inp: json, iv: ivKey);

  final stopwatchTwoTime = stopwatchTwo.elapsed;

  print('[encryptJsonBackground] ${type} $stopwatchTwoTime');

  return encryptedJson;
}
