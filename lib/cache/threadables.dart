import 'dart:convert';
import 'dart:async';

import 'package:syphon/cache/codec.dart';

Future<String> encryptJsonBackground(Map params) async {
  String json = params['json'];
  String cryptKey = params['cryptKey'];

  final cacheEncrypter = initCacheEncrypter(password: cryptKey);

  return Future.value(cacheEncrypter.encoder.convert(json));
}

Future<dynamic> decryptJsonBackground(Map params) async {
  String json = params['json'];
  String cryptKey = params['cryptKey'];

  final cacheEncrypter = initCacheEncrypter(password: cryptKey);

  return jsonDecode(cacheEncrypter.decoder.convert(json));
}
