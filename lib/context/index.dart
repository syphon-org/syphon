import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/secure-storage.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///
String generateContextId({required String id}) {
  final shaHash = sha256.convert(utf8.encode(id));
  return base64.encode(shaHash.bytes).toLowerCase().replaceAll(RegExp(r'[^\w]'), '').substring(0, 10);
}

Future<StoreContext> loadCurrentContext() async {
  try {
    final contextJson = await SecureStorage().read(key: StoreContext.ACCESS_KEY) ?? '[]';
    final allContexts = List<String>.from(await json.decode(contextJson));
    return StoreContext(current: allContexts.isNotEmpty ? allContexts[0] : StoreContext.DEFAULT);
  } catch (error) {
    return StoreContext(current: StoreContext.DEFAULT);
  }
}

Future<List<StoreContext>> loadContexts() async {
  try {
    final contextJson = await SecureStorage().read(key: StoreContext.ACCESS_KEY) ?? '[]';
    final allContexts = List<String>.from(await json.decode(contextJson));
    return allContexts.map((context) => StoreContext(current: context)).toList();
  } catch (error) {
    SecureStorage().delete(key: StoreContext.ACCESS_KEY);
    return [StoreContext(current: StoreContext.DEFAULT)];
  }
}

Future saveContext(String? current) async {
  if (current == null) return;

  final contextJson = await SecureStorage().read(key: StoreContext.ACCESS_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));
  final position = allContexts.indexOf(current);

// TODO: remove the domain logic of setting "current user" from this function
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  return SecureStorage().write(key: StoreContext.ACCESS_KEY, value: json.encode(allContexts));
}

Future deleteContext(String? current) async {
  if (current == null || current.isEmpty) return;

  final contextJson = await SecureStorage().read(key: StoreContext.ACCESS_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));

  allContexts.remove(current);

  return SecureStorage().write(key: StoreContext.ACCESS_KEY, value: json.encode(allContexts));
}
