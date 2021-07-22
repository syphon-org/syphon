import 'dart:convert';

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
Future<AppContext> loadCurrentContext() async {
  final contextJson = await SecureStorage().read(key: AppContext.STORAGE_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));
  return AppContext(current: allContexts.isNotEmpty ? allContexts[0] : AppContext.DEFAULT);
}

Future<List<AppContext>> loadContexts() async {
  final contextJson = await SecureStorage().read(key: AppContext.STORAGE_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));
  return allContexts.map((context) => AppContext(current: context)).toList();
}

Future saveContext(String? current) async {
  if (current == null) return;

  final contextJson = await SecureStorage().read(key: AppContext.STORAGE_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));
  final position = allContexts.indexOf(current);

// TODO: remove the domain logic of setting "current user" from this function
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  return SecureStorage().write(key: AppContext.STORAGE_KEY, value: json.encode(allContexts));
}

Future deleteContext(String? current) async {
  if (current == null || current.isEmpty) return;

  final contextJson = await SecureStorage().read(key: AppContext.STORAGE_KEY) ?? '[]';
  final allContexts = List<String>.from(await json.decode(contextJson));

  allContexts.remove(current);

  return SecureStorage().write(key: AppContext.STORAGE_KEY, value: json.encode(allContexts));
}
