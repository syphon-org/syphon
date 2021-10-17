import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/connectivity.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/drift/database.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/context/actions.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/home-screen.dart';
import 'package:syphon/views/intro/intro-screen.dart';
import 'package:syphon/views/navigation.dart';

class Syphon extends StatefulWidget {
  final Database? cache;
  final Database? storage;
  final StorageDatabase? storageCold;
  final Store<AppState> store;

  const Syphon(
    this.store,
    this.cache,
    this.storage,
    this.storageCold,
  );

  @override
  SyphonState createState() => SyphonState(
        store,
        cache,
        storage,
        storageCold,
      );
}

class SyphonState extends State<Syphon> with WidgetsBindingObserver {
  Store<AppState> store;
  Database? cache;
  Database? storage;
  StorageDatabase? storageCold;

  final globalScaffold = GlobalKey<ScaffoldMessengerState>();

  Widget defaultHome = HomeScreen();

  SyphonState(
    this.store,
    this.cache,
    this.storage,
    this.storageCold,
  );

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();

    // init all on state change listeners
    onInitListeners();

    // mutate messages
    store.dispatch(mutateMessagesAll());

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = IntroScreen();
    }
  }

  onInitListeners() async {
    // ** domain listeners ** TODO: potential race condition with
    await onDispatchListeners();
    await onStartListeners();

    // ** context handling **
    final currentContext = (await loadCurrentContext()).current;
    final currentUser = store.state.authStore.user;

    // Reset contexts if the current user has no accessToken (unrecoverable state)
    if (currentUser.accessToken == null && currentContext != AppContext.DEFAULT) {
      return onResetContext();
    }

    // init current auth state with current user
    store.state.authStore.authObserver?.add(
      currentUser,
    );

    // ** system listeners **
    await ConnectionService.startListener();
  }

  onDispatchListeners() async {
    await Future.wait([
      store.dispatch(initDeepLinks()) as Future,
      store.dispatch(startAuthObserver()) as Future,
      store.dispatch(startAlertsObserver()) as Future,
      store.dispatch(startContextObserver()) as Future,
    ]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  onStartListeners() async {
    // init auth listener
    store.state.authStore.onAuthStateChanged.listen(onAuthStateChanged);

    // init alerts listener
    store.state.alertsStore.onAlertsChanged.listen(onAlertsChanged);

    // set auth state listener
    store.state.authStore.onContextChanged.listen(onContextChanged);
  }

  @override
  // ignore: avoid_void_async
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        setupTheme(store.state.settingsStore.themeSettings);
        dismissAllNotifications(
          pluginInstance: globalNotificationPluginInstance,
        );
        saveNotificationsUnchecked(const {});
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        store.dispatch(setBackgrounded(true));
        break;
      case AppLifecycleState.detached:
        store.dispatch(setBackgrounded(true));
        break;
    }
  }

  onContextChanged(User? user) async {
    store.dispatch(SetGlobalLoading(loading: true));

    // stop old store listeners from running
    await onDestroyListeners();

    // stop old sync observer from running
    await store.dispatch(stopSyncObserver());

    // Stop saving to existing context databases
    await closeCache(cache);
    await closeStorage(storage);
    await closeColdStorage(storageCold);

    // final context switches
    final contextOld = await loadCurrentContext();
    String? contextNew;

    // save new user context
    if (user != null) {
      contextNew = generateContextId();
      await saveContext(contextNew);
    } else {
      // revert to another user context or default
      await deleteContext(contextOld.current);
      contextNew = (await loadCurrentContext()).current;
    }

    final cacheNew = await initCache(context: contextNew);
    final storageNew = await initStorage(context: contextNew);
    final storageColdNew = await initColdStorage(context: contextNew);

    final storeExisting = AppState(
      authStore: store.state.authStore.copyWith(user: user),
      settingsStore: store.state.settingsStore.copyWith(),
    );

    var existingUser = false;

    // users previously authenticated will not
    // have an accessToken passed thus,
    // let the persistor load the auth user instead
    if (user != null && user.accessToken != null) {
      if (user.accessToken!.isEmpty) {
        existingUser = true;
      }
    }

    if (user == null) {
      existingUser = true;
    }

    final storeNew = await initStore(
      cacheNew,
      storageNew,
      storageColdNew,
      existingUser: existingUser,
      existingState: storeExisting,
    );

    setState(() {
      cache = cacheNew;
      store = storeNew;
      storage = storageNew;
      storageCold = storageColdNew;
    });

    // reinitialize and start new store listeners
    await onDispatchListeners();
    await onStartListeners();

    final userNew = storeNew.state.authStore.user;
    final authObserverNew = storeNew.state.authStore.authObserver;

    // revert to another authed user if available and logging out
    if (user == null && userNew.accessToken != null && contextNew.isNotEmpty) {
      authObserverNew?.add(userNew);
    } else {
      authObserverNew?.add(user);
    }

    // wipe unauthenticated storage
    if (user != null) {
      onDeleteContext(AppContext(current: AppContext.DEFAULT));
    } else {
      // delete cache data if removing context / account (context is not default)
      onDeleteContext(contextOld);
    }

    storeNew.dispatch(SetGlobalLoading(loading: false));
  }

  onDeleteContext(AppContext context) async {
    if (context.current.isEmpty) {
      printInfo('[onContextChanged] DELETING DEFAULT CONTEXT');
    } else {
      printInfo('[onDeleteContext] DELETING CONTEXT DATA ${context.current}');
    }
    await deleteCache(context: context.current);
    await deleteStorage(context: context.current);
    await deleteColdStorage(context: context.current);
  }

  // Reset contexts if the current user has no accessToken (unrecoverable state)
  onResetContext() async {
    printError('[onResetContext] WARNING - RESETTING CONTEXT - HIT UNRECOVERABLE STATE');
    final allContexts = await loadContexts();

    await Future.forEach(
      allContexts,
      (AppContext context) async {
        await onDeleteContext(context);
      },
    );

    store.state.authStore.contextObserver?.add(
      null,
    );
  }

  onAuthStateChanged(User? user) async {
    final allContexts = await loadContexts();
    final defaultScreen = defaultHome.runtimeType;

    // No user is present and no contexts are availble to jump to
    if (user == null && allContexts.isEmpty && defaultScreen == HomeScreen) {
      defaultHome = IntroScreen();
      return NavigationService.clearTo(Routes.intro, context);
    }

    // No user is present during auth state change, but other contexts exist
    if (user == null && allContexts.isNotEmpty && defaultScreen == HomeScreen) {
      return;
    }

    // New user is found and previously was in an unauthenticated state
    if (user != null && user.accessToken != null && defaultScreen == IntroScreen) {
      defaultHome = HomeScreen();
      return NavigationService.clearTo(Routes.home, context);
    }

    // New user has been authenticated during an existing authenticated session
    // NOTE: skips users without accessTokens because that would mean its a multiaccount switch
    if (user != null &&
        user.accessToken != null &&
        user.accessToken!.isNotEmpty &&
        defaultScreen == HomeScreen) {
      return NavigationService.clearTo(Routes.home, context);
    }
  }

  onAlertsChanged(Alert alert) {
    Color? color;

    var alertOverride;

    switch (alert.type) {
      case 'error':
        if (!ConnectionService.isConnected() && !alert.offline) {
          alertOverride = 'Looks like you may be offline. Check your connection and try again.';
        }
        color = Colors.red;
        break;
      case 'warning':
        if (!ConnectionService.isConnected() && !alert.offline) {
          alertOverride = 'Looks like you may be offline. Check your connection and try again.';
        }
        color = Colors.red;
        break;
      case 'success':
        color = Colors.green;
        break;
      case 'info':
      default:
        color = Colors.grey;
    }

    final alertMessage = alertOverride ?? alert.message ?? alert.error ?? 'Unknown Error Occurred';

    globalScaffold.currentState?.showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(
        alertMessage,
        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
      ),
      duration: alert.duration,
      action: SnackBarAction(
        label: alert.action ?? 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          if (alert.onAction != null) {
            alert.onAction!();
          }
          globalScaffold.currentState?.removeCurrentSnackBar();
        },
      ),
    ));
  }

  onDestroyListeners() async {
    await ConnectionService.stopListener();
    await store.dispatch(stopContextObserver());
    await store.dispatch(stopAlertsObserver());
    await store.dispatch(stopAuthObserver());
    await store.dispatch(disposeDeepLinks());
  }

  @override
  void dispose() {
    onDestroyListeners();
    closeCache(cache);
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: localization.EasyLocalization(
          path: 'assets/translations',
          useOnlyLangCode: true,
          startLocale: Locale(formatLocale(store.state.settingsStore.language)),
          fallbackLocale: Locale(SupportedLanguages.defaultLang),
          useFallbackTranslations: true,
          supportedLocales: SupportedLanguages.list,
          child: StoreConnector<AppState, ThemeSettings>(
            distinct: true,
            converter: (store) => store.state.settingsStore.themeSettings,
            builder: (context, themeSettings) => MaterialApp(
              scaffoldMessengerKey: globalScaffold,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              debugShowCheckedModeBanner: false,
              theme: setupTheme(themeSettings, generateThemeData: true),
              navigatorKey: NavigationService.navigatorKey,
              routes: NavigationProvider.getRoutes(),
              home: defaultHome,
            ),
          ),
        ),
      );
}
