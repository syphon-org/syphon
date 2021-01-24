// Dart imports:
import 'dart:math';
import 'dart:convert';

String generateClientSecret({int length}) {
  final random = Random.secure();
  final values = List<int>.generate(length, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
