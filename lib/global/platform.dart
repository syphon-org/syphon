import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';

import 'package:syphon/global/print.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_linux/path_provider_linux.dart';
import 'package:syphon/store/sync/background/service.dart';

///
/// Init Platform Dependencies
///
/// init all specific dependencies needed
/// to run Syphon on a specific platform
///
Future<void> initPlatformDependencies() async {
  // disable debugPrint when in release mode
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
    printDebug = (String message, {String? title}) {};
    printInfo = (String message, {String? title}) {};
    printError = (String message, {String? title}) {};
  }

  // init platform overrides for compatability with dart libs
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  if (Platform.isLinux) {
    PathProviderLinux.register();

    final appDir = File(Platform.script.toFilePath()).parent;
    final libolmDir = File(path.join(appDir.path, 'lib/libolm.so'));
    final libsqliteDir = File(path.join(appDir.path, 'lib/libsqlite3.so'));
    final libolmExists = await libolmDir.exists();
    final libsqliteExists = await libsqliteDir.exists();

    if (libolmExists) {
      DynamicLibrary.open(libolmDir.path);
    } else {
      printError('[linux] exists ${libolmExists} ${libolmDir.path}');
    }

    if (libsqliteExists) {
      open.overrideFor(OperatingSystem.linux, () {
        return DynamicLibrary.open(libsqliteDir.path);
      });
    } else {
      printError('[linux] exists ${libsqliteExists} ${libsqliteDir.path}');
    }
  }

  // init window mangment for desktop builds
  if (Platform.isMacOS) {
    final directory = await getApplicationSupportDirectory();
    printInfo('[macos] ${directory.path}');
    // DynamicLibrary.open('libolm.dylib');
  }

  // init background sync for Android only
  if (Platform.isAndroid) {
    final backgroundSyncStatus = await BackgroundSync.init();
    printInfo('[main] background service started $backgroundSyncStatus');
  }
}
