import 'dart:convert';

import 'package:syphon/context/types.dart';
import 'package:syphon/global/libs/storage/secure-storage.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

const ALL_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-all';
const CURRENT_APP_CONTEXT_KEY = '${Values.appLabel}@app-context-current';

resetAppContext() async {
  try {
    SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode([]));
    SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(AppContext.DEFAULT));
  } catch (error) {
    printError('[loadCurrentContext] ERROR SAVING DEFAULTS ${error.toString()}');
  }
}

saveAppContexts(List<AppContext>? all) async {
  if (all == null) return;

  SecureStorage().write(key: ALL_APP_CONTEXT_KEY, value: json.encode(all));
}

saveAppContextCurrent(AppContext? current) async {
  if (current == null) return;

  SecureStorage().write(key: CURRENT_APP_CONTEXT_KEY, value: json.encode(current));
}

saveAppContext(AppContext? current) async {
  if (current == null) return;

  final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
  final allContexts = List<AppContext>.from(await json.decode(contextJson));
  final position = allContexts.indexOf(current);

  saveAppContextCurrent(current);

  // TODO: remove the domain logic of setting "current user" from this function
  if (position == -1) {
    allContexts.add(current);
  } else {
    allContexts.removeAt(position);
    allContexts.insert(0, current);
  }

  return saveAppContexts(allContexts);
}

loadCurrentAppContext() async {
  try {
    final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
    final allContexts = List<AppContext>.from(await json.decode(contextJson));

    final currentContext = allContexts.isNotEmpty ? allContexts[0] : AppContext();

    saveAppContextCurrent(currentContext);

    return currentContext;
  } catch (error) {
    printError('[loadCurrentContext] ERROR LOADING CURRENT CONTEXT ${error.toString()}');

    resetAppContext();

    return AppContext();
  }
}

loadAllContexts() async {
  try {
    final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
    return List<AppContext>.from(await json.decode(contextJson));
  } catch (error) {
    printError('[loadContexts] ERROR LOADING ALL CONTEXTS ${error.toString()}');

    resetAppContext();
    return [AppContext()];
  }
}

deleteAppContext(AppContext? current) async {
  if (current == null) return;

  final contextJson = await SecureStorage().read(key: ALL_APP_CONTEXT_KEY) ?? '[]';
  final allContexts = List<AppContext>.from(await json.decode(contextJson));

  allContexts.remove(current);

  if (allContexts.isNotEmpty) {
    saveAppContextCurrent(allContexts.first);
  }

  return saveAppContexts(allContexts);
}
