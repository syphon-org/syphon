import 'dart:convert';

import 'package:crypto/crypto.dart';

bool verifyPinHash({required String passcode, required String hash}) {
  final shaHash = sha256.convert(utf8.encode(passcode));
  return base64.encode(shaHash.bytes) == hash;
}

String generatePinHash({required String passcode}) {
  return base64.encode(sha256.convert(utf8.encode(passcode)).bytes);
}
