import 'dart:convert';

import 'package:syphon/context/types.dart';
import 'package:syphon/global/libs/storage/secure-storage.dart';
import 'package:syphon/global/print.dart';

// ignore: non_constant_identifier_names
Future<List<AppContext>> loadContexts_DEPRECATED() async {
  try {
    final contextJson = await SecureStorage().read(key: AppContext.ALL_CONTEXT_KEY) ?? '[]';
    final allContexts = List<String>.from(await json.decode(contextJson));
    return allContexts.map((context) => AppContext(id: context)).toList();
  } catch (error) {
    printError('[loadContexts] ERROR LOADING ALL CONTEXTS ${error.toString()}');
    SecureStorage().delete(key: AppContext.ALL_CONTEXT_KEY);
    return [AppContext(id: AppContext.DEFAULT)];
  }
}
