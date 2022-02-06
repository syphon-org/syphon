import 'dart:async';

import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/auth.dart';
import 'package:syphon/context/storage.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/connectivity.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/storage/database.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/alerts/model.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/auth/context/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/home-screen.dart';
import 'package:syphon/views/intro/intro-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/prelock.dart';

class Syphon extends StatefulWidget {
  final Database? cache;
  final Store<AppState> store;
  final StorageDatabase? storage;

  const Syphon(
    this.cache,
    this.store,
    this.storage,
  );

  static Future setAppContext(BuildContext buildContext, AppContext appContext) {
    return buildContext.findAncestorStateOfType<SyphonState>()!.onContextSet(appContext);
  }

  static AppContext getAppContext(BuildContext buildContext) {
    return buildContext.findAncestorStateOfType<SyphonState>()!.appContext ?? AppContext();
  }

  static Future reloadCurrentContext(BuildContext buildContext) {
    return buildContext.findAncestorStateOfType<SyphonState>()!.reloadCurrentContext();
  }

  @override
  SyphonState createState() => SyphonState();
}

class SyphonState extends State<Syphon> with WidgetsBindingObserver {
  late Store<AppState> store;

  Database? cache;
  StorageDatabase? storage;
  AppContext? appContext;

  final globalScaffold = GlobalKey<ScaffoldMessengerState>();

  Widget defaultHome = HomeScreen();

  SyphonState();

  @override
  void initState() {
    cache = widget.cache;
    store = widget.store;
    storage = widget.storage;

    WidgetsBinding.instance?.addObserver(this);

    // init all on state change listeners
    onInitListeners();

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = IntroScreen();
    }

    super.initState();
  }

  reloadCurrentContext() async {
    // context handling
    final currentContext = await loadContextCurrent();
    appContext = currentContext;
  }

  onInitListeners() async {
    // ** domain listeners **
    await onDispatchListeners();
    await onStartListeners();

    // context handling
    final currentContext = await loadContextCurrent();
    appContext = currentContext;

    // auth handling
    final currentUser = store.state.authStore.user;

    // Reset contexts if the current user has no accessToken (unrecoverable state)
    if (currentUser.accessToken == null && currentContext.id != AppContext.DEFAULT) {
      return onResetContext();
    }

    // init current auth state with current user
    store.state.authStore.authObserver?.add(
      currentUser,
    );
  }

  onDispatchListeners() async {
    await Future.wait([
      store.dispatch(initDeepLinks()) as Future,
      store.dispatch(startAuthObserver()) as Future,
      store.dispatch(startAlertsObserver()) as Future,
      store.dispatch(startContextObserver()) as Future,
    ]);
  }

  onStartListeners() async {
    // ** system listeners **
    await ConnectionService.startListener();

    // init auth listener
    store.state.authStore.onAuthStateChanged.listen(onAuthStateChanged);

    // set auth state listener
    store.state.authStore.onContextChanged.listen(onContextChanged);

    // init alerts listener
    store.state.alertsStore.onAlertsChanged.listen(onAlertsChanged);
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

  onContextSet(AppContext appContext) async {
    await saveContextCurrent(appContext);
    await Prelock.restart(context);
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

    // final context switches
    final contextOld = await loadContextCurrent();
    AppContext? contextNew;

    // save new user context
    if (user != null) {
      final contextId = generateContextId_DEPRECATED(id: user.userId!);
      contextNew = await findContext(contextId);

      if (contextNew.id.isEmpty) {
        contextNew = AppContext(id: contextId);
      }

      await saveContext(contextNew);

      if (contextNew.pinHash.isNotEmpty) {
        return Prelock.toggleLocked(context, '', override: true);
      }
    } else {
      // revert to another user context or default
      await deleteContext(contextOld);
      contextNew = await loadContextNext();
    }

    // Context cannot be null after above is run
    final cacheNew = await initCache(context: contextNew);
    final storageNew = await initStorage(context: contextNew);

    // allow referencing current app context throughout the app
    appContext = contextNew;

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
      existingUser: existingUser,
      existingState: storeExisting,
    );

    setState(() {
      cache = cacheNew;
      store = storeNew;
      storage = storageNew;
    });

    // reinitialize and start new store listeners
    await onDispatchListeners();
    await onStartListeners();

    final userNew = storeNew.state.authStore.user;
    final authObserverNew = storeNew.state.authStore.authObserver;

    // revert to another authed user if available and logging out
    if (user == null && userNew.accessToken != null && contextNew.id.isNotEmpty) {
      authObserverNew?.add(userNew);
    } else {
      authObserverNew?.add(user);
    }

    // wipe unauthenticated storage
    if (user != null) {
      onDeleteContextStorage(AppContext(id: AppContext.DEFAULT));
    } else {
      // delete cache data if removing context / account (context is not default)
      onDeleteContextStorage(contextOld);
    }

    storeNew.dispatch(SetGlobalLoading(loading: false));
  }

  onDeleteContextStorage(AppContext context) async {
    if (context.id.isEmpty) {
      printInfo('[onContextChanged] DELETING DEFAULT CONTEXT');
    } else {
      printInfo('[onDeleteContext] DELETING CONTEXT DATA ${context.id}');
    }

    await deleteCache(context: context);
    await deleteStorage(context: context);
    await deleteContext(context);
  }

  // Reset contexts if the current user has no accessToken (unrecoverable state)
  onResetContext() async {
    printError('[onResetContext] WARNING - RESETTING CONTEXT - HIT UNRECOVERABLE STATE');

    resetContextsAll();

    store.state.authStore.contextObserver?.add(null);
  }

  onAuthStateChanged(User? user) async {
    final allContexts = await loadContextsAll();
    final defaultScreen = defaultHome.runtimeType;
    final currentRoute = NavigationService.currentRoute();

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
        defaultScreen == HomeScreen &&
        currentRoute != Routes.root) {
      return NavigationService.clearTo(Routes.home, context);
    }
  }

  onAlertsChanged(Alert alert) {
    Color? color;

    var alertOverride;

    switch (alert.type) {
      case 'error':
        if (!ConnectionService.isConnected() && !alert.offline) {
          alertOverride = Strings.alertOffline;
        }
        color = Colors.red;
        break;
      case 'warning':
        if (!ConnectionService.isConnected() && !alert.offline) {
          alertOverride = Strings.alertOffline;
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

    final alertMessage = alertOverride ?? alert.message ?? alert.error ?? Strings.alertUnknown;

    globalScaffold.currentState?.showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(
        alertMessage,
        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
      ),
      duration: alert.duration,
      action: SnackBarAction(
        label: alert.action ?? Strings.buttonDismiss,
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
          startLocale: Locale(findLocale(store.state.settingsStore.language, context: context)),
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
              builder: (context, child) => Directionality(
                textDirection: SupportedLanguages.rtl.contains(store.state.settingsStore.language)
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: child!,
              ),
            ),
          ),
        ),
      );
}
