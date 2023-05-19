import 'dart:convert';

import 'package:cryptography/cryptography.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
String shasum(List<int> bytes) {
  final shaHash = Sha1().toSync().hashSync(bytes);
  return base64.encode(shaHash.bytes);
}
