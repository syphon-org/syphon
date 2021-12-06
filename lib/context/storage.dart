import 'dart:convert';

import 'package:syphon/cache/index.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/libs/storage/secure-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/index.dart';

const ALL_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-all';
const CURRENT_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-current';

Future saveContextCurrent(AppContext? current) async {
  if (current == null) return;

  SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(current));
}

Future saveContext(AppContext? current) async {
  if (current == null) return;

  final allContexts = await loadContextsAll();
  final position = allContexts.indexWhere((c) => c.id == current.id);

  // TODO: handle setting current context external to saveContext
  saveContextCurrent(current);

  // both saves new or effectively updates existing
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  return saveContextsAll(allContexts);
}

Future saveContextsAll(List<AppContext>? all) async {
  if (all == null) return;

  SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode(all));
}

Future<AppContext> loadContextCurrent() async {
  try {
    final contextJson = await SecureStorage().read(key: CURRENT_APP_CONTEXT_KEY);
    final currentContext = AppContext.fromJson(await json.decode(contextJson!));

    return currentContext;
  } catch (error) {
    printError('[loadCurrentContext] ERROR LOADING CURRENT CONTEXT ${error.toString()}');

    try {
      return loadContextNext();
    } catch (error) {
      printError('[loadNextContext] ERROR LOADING NEXT CONTEXT - RESETTING CONTEXT');
      resetContextsAll();
      return AppContext();
    }
  }
}

Future<AppContext> loadContextNext() async {
  try {
    final allContexts = await loadContextsAll();
    return allContexts.isNotEmpty ? allContexts[0] : AppContext();
  } catch (error) {
    printError('[loadNextContext] ERROR LOADING NEXT CONTEXT ${error.toString()}');

    return AppContext();
  }
}

Future<List<AppContext>> loadContextsAll() async {
  try {
    final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
    return List.from(await json.decode(contextJson)).map((c) => AppContext.fromJson(c)).toList();
  } catch (error) {
    printError('[loadAllContexts] ERROR LOADING ALL CONTEXTS ${error.toString()}');

    resetContextsAll();

    return [AppContext()];
  }
}

Future deleteContext(AppContext? current) async {
  if (current == null) return;

  final allContexts = await loadContextsAll();

  allContexts.remove(current);

  if (allContexts.isNotEmpty) {
    saveContextCurrent(allContexts.first);
  } else {
    saveContextCurrent(AppContext());
  }

  return saveContextsAll(allContexts);
}

resetContextsAll() async {
  try {
    final allContexts = await loadContextsAll();

    await Future.forEach(
      allContexts,
      (AppContext context) async {
        await deleteCache(context: context);
        await deleteStorage(context: context);
        await deleteStorageOLD(context: context);
      },
    );

    await SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode([]));
    await SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(AppContext()));
  } catch (error) {
    printError('[resetAllContexts] ERROR RESETTING CONTEXT STORAGE ${error.toString()}');
  }
}

// TODO: remove after 0.2.3
// ignore: non_constant_identifier_names
migrateContexts_MIGRATION() async {
  final oldContexts = await loadContexts_DEPRECATED();

  if (oldContexts.isEmpty) return;

  await saveContextsAll(oldContexts);

  await SecureStorage().delete(key: AppContext.ALL_CONTEXT_KEY);
  await SecureStorage().delete(key: AppContext.CURRENT_CONTEXT_KEY);
}
