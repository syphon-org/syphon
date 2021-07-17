import 'package:flutter/material.dart';

import 'package:syphon/cache/index.dart';
import 'package:syphon/global/platform.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/syphon.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding();
  WidgetsFlutterBinding.ensureInitialized();

  // init platform specific code
  await initPlatformDependencies();

  // init hot cache
  final cache = await initCache();

  // init cold storage
  final storage = await initStorage();

  // init redux store
  final store = await initStore(cache, storage);

  // init app
  runApp(Syphon(store, cache, storage));
}
