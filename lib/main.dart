import 'dart:io';

import 'package:flutter/material.dart';

import 'package:syphon/cache/index.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/global/platform.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/prelock.dart';
import 'package:syphon/views/syphon.dart';

import 'global/https.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init platform specific code
  await initPlatformDependencies();

  // pull current context / nullable
  final context = await loadCurrentContext();

  // init app
  runApp(Prelock(
    appContext: context,
    enabled: context.pinHash.isNotEmpty,
  ));
}
