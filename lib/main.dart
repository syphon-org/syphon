import 'package:flutter/material.dart';

import 'package:syphon/context/storage.dart';
import 'package:syphon/global/platform.dart';
import 'package:syphon/views/prelock.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init platform specific code
  await initPlatformDependencies();

  // TODO: remove after 0.2.3
  await migrateContexts_MIGRATION();

  // pull current context / nullable
  final context = await loadContextCurrent();

  // init app
  runApp(Prelock(
    appContext: context,
    enabled: context.id.isNotEmpty && context.pinHash.isNotEmpty,
  ));
}
