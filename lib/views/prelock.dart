import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/https.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/intro/lock-screen.dart';
import 'package:syphon/views/intro/signup/loading-screen.dart';
import 'package:syphon/views/navigation.dart';
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

  static Future? toggleLocked(BuildContext context, String pin, {bool? override}) {
    return context
        .findAncestorStateOfType<_PrelockState>()!
        .toggleLocked(pin: pin, override: override);
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
  onMounted() async {
    if (!locked) {
      await _onLoadStorage();

      printDebug('[Prelock] onMounted LOADED STORAGE ${widget.appContext.id}');

      _navigatorKey.currentState?.pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => buildSyphon(),
          transitionDuration: Duration(seconds: 200),
        ),
      );
    }
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

  toggleLocked({required String pin, bool? override}) async {
    final lockedNew = override ?? !locked;

    if (!lockedNew) {
      await _onLoadStorage(pin: pin);

      setState(() {
        locked = false;
      });

      _navigatorKey.currentState?.pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation1, animation2) => buildSyphon(),
            transitionDuration: Duration(seconds: 200),
          ),
          ModalRoute.withName('/'));
    } else {
      setState(() {
        locked = true;
      });

      setState(() {
        store = null;
        cache = null;
        storage = null;
      });

      showLockScreen();
    }
  }

  _onLoadStorage({String pin = Values.empty}) async {
    final appContext = widget.appContext;

    // init hot caches
    final cachePreload = await initCache(context: appContext);

    // init cold storage
    final storagePreload = await initStorage(context: appContext, pin: pin);

    // init redux store
    final storePreload = await initStore(cachePreload, storagePreload);

    // init http client
    httpClient = createClient(proxySettings: storePreload.state.settingsStore.proxySettings);

    setState(() {
      cache = cachePreload;
      storage = storagePreload;
      store = storePreload;
    });
  }

  buildLockScreen() => LockScreen(
        appContext: widget.appContext,
      );

  buildSyphon() => WillPopScope(
        onWillPop: () => NavigationService.goBack(),
        child: Syphon(
          cache,
          store!,
          storage,
        ),
      );

  buildHome() {
    if (widget.enabled) {
      return buildLockScreen();
    }

    return LoadingScreen(dark: Platform.isAndroid);
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: buildHome(),
          navigatorKey: _navigatorKey,
          routes: {
            '/unlocked': (context) => buildSyphon(),
            '/lock-screen': (context) => buildLockScreen(),
            '/loading-screen': (context) => LoadingScreen(dark: Platform.isAndroid),
          },
        ),
      );
}
