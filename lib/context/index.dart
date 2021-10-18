import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/libs/storage/secure-storage.dart';
import 'package:syphon/global/print.dart';

///
/// Store Context
///
/// Helps select specifically addressed hot cache and cold storage
/// to load user account data from to redux store
///
/// allows multiaccount feature to be domain logic independent
///

String generateContextId() {
  final shaHash = sha256.convert(utf8.encode(getRandomString(10)));
  return base64.encode(shaHash.bytes).toLowerCase().replaceAll(RegExp(r'[^\w]'), '').substring(0, 10);
}

// Switch to generating UserID independent context IDs that can still be managed globally
// ignore: non_constant_identifier_names
String generateContextId_DEPRECATED({required String id}) {
  final shaHash = sha256.convert(utf8.encode(id));
  return base64.encode(shaHash.bytes).toLowerCase().replaceAll(RegExp(r'[^\w]'), '').substring(0, 10);
}

// TODO: convert to setCurrentContext after 0.1.14 release
Future setCurrentContext(String? current) async {
  if (current == null) return;

  SecureStorage().write(key: AppContext.CURRENT_CONTEXT_KEY, value: current);
}

Future<AppContext> loadCurrentContext() async {
  try {
    final contextJson = await SecureStorage().read(key: AppContext.ALL_CONTEXT_KEY) ?? '[]';
    final allContexts = List<String>.from(await json.decode(contextJson));

    setCurrentContext(allContexts.isNotEmpty ? allContexts[0] : AppContext.DEFAULT);

    return AppContext(current: allContexts.isNotEmpty ? allContexts[0] : AppContext.DEFAULT);
  } catch (error) {
    printError('[loadCurrentContext] ERROR LOADING CURRENT CONTEXT ${error.toString()}');

    try {
      SecureStorage().write(key: AppContext.ALL_CONTEXT_KEY, value: json.encode([]));
      SecureStorage().write(key: AppContext.CURRENT_CONTEXT_KEY, value: json.encode(AppContext.DEFAULT));
    } catch (error) {
      printError('[loadCurrentContext] ERROR SAVING DEFAULTS ${error.toString()}');
    }

    setCurrentContext(AppContext.DEFAULT);
    return AppContext(current: AppContext.DEFAULT);
  }
}

Future saveContext(String? current) async {
  if (current == null) return;

  final contextJson = await SecureStorage().read(key: AppContext.ALL_CONTEXT_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));
  final position = allContexts.indexOf(current);

  setCurrentContext(current);

  // TODO: remove the domain logic of setting "current user" from this function
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  return SecureStorage().write(key: AppContext.ALL_CONTEXT_KEY, value: json.encode(allContexts));
}

Future<List<AppContext>> loadContexts() async {
  try {
    final contextJson = await SecureStorage().read(key: AppContext.ALL_CONTEXT_KEY) ?? '[]';
    final allContexts = List<String>.from(await json.decode(contextJson));
    return allContexts.map((context) => AppContext(current: context)).toList();
  } catch (error) {
    printError('[loadContexts] ERROR LOADING ALL CONTEXTS ${error.toString()}');
    SecureStorage().delete(key: AppContext.ALL_CONTEXT_KEY);
    return [AppContext(current: AppContext.DEFAULT)];
  }
}

Future deleteContext(String? current) async {
  if (current == null || current.isEmpty) return;

  final contextJson = await SecureStorage().read(key: AppContext.ALL_CONTEXT_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));

  allContexts.remove(current);

  return SecureStorage().write(key: AppContext.ALL_CONTEXT_KEY, value: json.encode(allContexts));
}
