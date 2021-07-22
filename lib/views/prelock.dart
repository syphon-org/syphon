import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/views/applock.dart';
import 'package:syphon/views/intro/lock-screen.dart';
import 'package:syphon/views/syphon.dart';

class Prelock extends StatefulWidget {
  final bool enabled;
  final AppContext appContext;

  const Prelock({
    required this.appContext,
    required this.enabled,
  });

  static restart(BuildContext context) {
    context.findAncestorStateOfType<_PrelockState>()!.restart();
  }

  static Future? togglePermitted(BuildContext context) {
    return context.findAncestorStateOfType<_PrelockState>()!.togglePermitted();
  }

  @override
  _PrelockState createState() => _PrelockState();
}

class _PrelockState extends State<Prelock> {
  Key key = UniqueKey();

  bool enabled = false;

  Database? cache;
  Database? storage;
  Store<AppState> store = Store<AppState>(
    appReducer,
    initialState: AppState(),
    middleware: [],
  );

  @override
  void initState() {
    super.initState();
    enabled = widget.enabled;
  }

  restart() {
    setState(() {
      key = UniqueKey();
    });
  }

  togglePermitted() async {
    return await onLoadStores();
  }

  onLoadStores() async {
    final appContext = widget.appContext;

    // init hot cache
    final cachePreload = await initCache(context: appContext.current);

    // init cold storage
    final storagePreload = await initStorage(context: appContext.current);

    // init redux store
    final storePreload = await initStore(cachePreload, storagePreload);

    setState(() {
      cache = cachePreload;
      storage = storagePreload;
      store = storePreload;
    });
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: LockScreen(
            appContext: widget.appContext,
            enabled: widget.enabled,
            child: Syphon(
              widget.appContext,
              store,
              storage,
              cache,
            ),
          ),
        ),
      );
}
