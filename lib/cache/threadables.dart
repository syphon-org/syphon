import 'dart:async';
import 'dart:convert';

import 'package:syphon/cache/codec.dart';

Future<String> encryptJsonBackground(Map params) async {
  final String json = params['json'];
  final String cacheKey = params['cacheKey'];

  final cacheEncrypter = initCacheEncrypter(password: cacheKey);

  return Future.value(cacheEncrypter.encoder.convert(json));
}

Future<dynamic> decryptJsonBackground(Map params) async {
  final String json = params['json'];
  final String cacheKey = params['cacheKey'];

  final cacheEncrypter = initCacheEncrypter(password: cacheKey);

  return jsonDecode(cacheEncrypter.decoder.convert(json));
}
