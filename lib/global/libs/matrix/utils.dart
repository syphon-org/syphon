// Dart imports:
import 'dart:math';
import 'dart:convert';

String generateClientSecret({required int length}) {
  final random = Random.secure();
  final values = List<int>.generate(length, (i) => random.nextInt(255));
  return base64UrlEncode(values);
}
