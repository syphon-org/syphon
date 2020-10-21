// Dart imports:
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:steel_crypt/steel_crypt.dart';

/**
 * Clock functions in code
 * 
 * final stopwatch = Stopwatch()..start();
 * print('[fetchRooms] TIMESTAMP ${stopwatch.elapsed}');
 * stopwatch.stop();
 */

List<int> fibonacci(int n) {
  if (n == 0) {
    return [0];
  }
  if (n == 1) {
    return [0, 1];
  }
  final series = fibonacci(n - 1);
  series.add(series[series.length - 1] + series[series.length - 2]);
  return series;
}

void printJson(Map jsonMap) {
  JsonEncoder encoder = new JsonEncoder.withIndent('  ');
  String prettyEvent = encoder.convert(jsonMap);
  debugPrint(prettyEvent, wrapWidth: 2048);
}

// TODO: not sure if needed because the decryption of the cache will always be needed synchonously
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

  print('[encryptJsonBackground] ENCRYPTION AES ${type}  $stopwatchTwoTime');

  return encryptedJson;
}
