import 'dart:convert';

import 'package:crypto/crypto.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
///
String generateContextId({required String id}) {
  final shaHash = sha256.convert(utf8.encode(id));
  return base64.encode(shaHash.bytes).toLowerCase().replaceAll(RegExp(r'[^\w]'), '').substring(0, 10);
}

bool verifyPinHash({required String passcode, required String hash}) {
  final shaHash = sha256.convert(utf8.encode(passcode));
  return base64.encode(shaHash.bytes) == hash;
}

String generatePinHash({required String passcode}) {
  return base64.encode(sha256.convert(utf8.encode(passcode)).bytes);
}
