import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/https.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/intro/lock-screen.dart';
import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/syphon.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

///
/// Prelock
///
/// Locks the app by removing the storage
/// references of the widget and potentially
/// freeing what is in RAM. None of the storage
/// references should be available when locked
///
class Prelock extends StatefulWidget {
  final bool enabled;
  final AppContext appContext;
  final Duration backgroundLockLatency;

  const Prelock({
    required this.enabled,
    required this.appContext,
    this.backgroundLockLatency = const Duration(seconds: 0),
  });

  static restart(BuildContext context) {
    context.findAncestorStateOfType<_PrelockState>()!.restart();
  }

  static Future? toggleLocked(BuildContext context) {
    return context.findAncestorStateOfType<_PrelockState>()!.toggleLocked();
  }

  @override
  _PrelockState createState() => _PrelockState();
}

class _PrelockState extends State<Prelock> with WidgetsBindingObserver, Lifecycle<Prelock> {
  Key key = UniqueKey();
  Key storekey = UniqueKey();

  static final GlobalKey<NavigatorState> _navigatorKey = GlobalKey();

  bool locked = false;
  bool enabled = false;
  bool _didUnlockForAppLaunch = false;
  Timer? backgroundLockLatencyTimer;

  Database? cache;
  Database? storageOld;
  StorageDatabase? storage;
  Store<AppState>? store;

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);

    locked = widget.enabled;
    enabled = widget.enabled;
    _didUnlockForAppLaunch = !widget.enabled;

    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!enabled) {
      return;
    }

    if (state == AppLifecycleState.paused && (!locked && _didUnlockForAppLaunch)) {
      backgroundLockLatencyTimer = Timer(widget.backgroundLockLatency, () => showLockScreen());
    }

    if (state == AppLifecycleState.resumed) {
      backgroundLockLatencyTimer?.cancel();
    }

    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);

    backgroundLockLatencyTimer?.cancel();

    super.dispose();
  }

  showLockScreen() {
    locked = true;

    if (_navigatorKey.currentState == null) return;

    return _navigatorKey.currentState!.pushNamed('/lock-screen');
  }

  restart() {
    setState(() {
      key = UniqueKey();
    });
  }

  toggleLocked() async {
    locked = !locked;

    if (!locked) {
      await onLoadStores();

      setState(() {
        locked = false;
      });

      _navigatorKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => buildSyphon(),
          transitionDuration: Duration(seconds: 0),
        ),
      );
    } else {
      setState(() {
        locked = true;
      });

      setState(() {
        store = null;
        cache = null;
        storage = null;
        storageOld = null;
      });
    }
  }

  onLoadStores() async {
    final appContext = widget.appContext;

    // init hot caches
    final cachePreload = await initCache(context: appContext.current);

    // init cold storage
    final storagePreload = await initStorage(context: appContext.current);

    // init cold storage - old
    final storageOldPreload = await initStorageOLD(context: appContext.current);

    // init redux store
    final storePreload = await initStore(cache, storageOld, storagePreload);

    // init http client
    if (storePreload.state.settingsStore.proxySettings.enabled) {
      httpClient = createProxiedClient(storePreload.state.settingsStore.proxySettings);
    } else {
      httpClient = createClient();
    }

    setState(() {
      store = storePreload;
      cache = cachePreload;
      storage = storagePreload;
      storageOld = storageOldPreload;
    });
  }

  buildLockScreen() {
    return LockScreen(appContext: widget.appContext);
  }

  buildSyphon() {
    return Syphon(
      store!,
      cache,
      storageOld,
      storage,
    );
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: widget.enabled ? buildLockScreen() : buildSyphon(),
          navigatorKey: _navigatorKey,
          routes: {
            '/lock-screen': (context) => buildLockScreen(),
            '/unlocked': (context) => locked ? LoadingScreen() : buildSyphon()
          },
        ),
      );
}
