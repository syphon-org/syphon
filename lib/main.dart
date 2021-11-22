import 'dart:io';

import 'package:flutter/material.dart';

import 'package:http_proxy_override/http_proxy_override.dart';

import 'package:syphon/cache/index.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/global/platform.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/prelock.dart';
import 'package:syphon/views/syphon.dart';

// ignore: avoid_void_async
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // init platform specific code
  await initPlatformDependencies();

  // pull current context / nullable
  final context = await loadCurrentContext();

  // init hot cache
  final cache = await initCache(context: context.current);

  // init cold storage - old
  final storage = await initStorage(context: context.current);

  // init cold storage
  final storageCold = await initColdStorage(context: context.current);

  // init redux store
  final store = await initStore(cache, storage, storageCold);

  // init http proxy, if required
  if (store.state.settingsStore.httpProxySettings.enabled) {
    final HttpProxyOverride httpProxy = await HttpProxyOverride.createHttpProxy();

    httpProxy.port = store.state.settingsStore.httpProxySettings.port;
    httpProxy.host = store.state.settingsStore.httpProxySettings.host;

    HttpOverrides.global = httpProxy;
  }

  // init app
  runApp(
    Prelock(
      child: Syphon(
        store,
        cache,
        storage,
        storageCold,
      ),
    ),
  );
}
