import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/context/index.dart';
import 'package:syphon/context/types.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';

import 'package:syphon/global/themes.dart';
import 'package:syphon/global/values.dart';
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
  final Store<AppState> store;

  const Syphon(
    this.store,
    this.cache,
    this.storage,
  );

  @override
  SyphonState createState() => SyphonState(
        store,
        cache,
        storage,
      );
}

class SyphonState extends State<Syphon> with WidgetsBindingObserver {
  Database? cache;
  Database? storage;
  Store<AppState> store;
  final globalScaffold = GlobalKey<ScaffoldMessengerState>();

  Widget defaultHome = HomeScreen();

  SyphonState(
    this.store,
    this.cache,
    this.storage,
  );

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();

    // init all on state change listeners
    onInitListenersFirst();

    // mutate messages
    store.dispatch(mutateMessagesAll());

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = IntroScreen();
    }
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

  ///
  /// a.k.a. onMounted()
  ///
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onStartListeners();
  }

  onInitListenersFirst() {
    onInitListeners();

    // init current auth state with current user
    store.state.authStore.authObserver?.add(
      store.state.authStore.user,
    );
  }

  onInitListeners() {
    store.dispatch(initDeepLinks());
    store.dispatch(startAuthObserver());
    store.dispatch(startAlertsObserver());
    store.dispatch(startContextObserver());
  }

  onStartListeners() {
    // init auth listener
    store.state.authStore.onAuthStateChanged.listen(onAuthStateChanged);

    // set auth state listener
    store.state.authStore.onContextChanged.listen(onContextChanged);

    // init alerts listener
    store.state.alertsStore.onAlertsChanged.listen(onAlertsChanged);
  }

  onDestroyListeners() async {
    await store.dispatch(stopContextObserver());
    await store.dispatch(stopAlertsObserver());
    await store.dispatch(stopAuthObserver());
    await store.dispatch(disposeDeepLinks());
  }

  onContextChanged(User? user) async {
    store.dispatch(SetGlobalLoading(loading: true));

    // stop old store listeners from running
    await onDestroyListeners();

    // stop old sync observer from running
    await store.dispatch(stopSyncObserver());

    // final context switches
    final contextOld = await loadCurrentContext();
    var contextNew;

    // Stop saving to existing context databases
    await closeCache(cache);
    await closeStorage(storage);

    // save new user context
    if (user != null) {
      contextNew = generateContextId(id: user.userId!);
      await saveContext(contextNew);
    } else {
      // Remove old context and check all remaining
      print('[onContextChanged] DELETING ${contextOld.current}');
      await deleteContext(contextOld.current);
      contextNew = (await loadCurrentContext()).current;
      print('[onContextChanged] SETTING TO PREVIOUS CONTEXT ${contextNew}');
    }

    final cacheNew = await initCache(context: contextNew);
    final storageNew = await initStorage(context: contextNew);

    final storeExisting = AppState(
      authStore: store.state.authStore.copyWith(user: user),
      settingsStore: store.state.settingsStore.copyWith(),
    );

    // users previously authenticated will not
    // have an accessToken passed thus,
    // let the persistor load the auth user instead
    var existingUser = false;
    if (user != null && user.accessToken != null) {
      printInfo(user.toString());

      if (user.accessToken!.isEmpty) {
        existingUser = true;
      }
      // otherwise, do the same thing if logging out of a user
      // but another exists (really switching users)
    } else if (user == null && contextNew != StoreContext.DEFAULT) {
      existingUser = true;
    }

    printInfo(existingUser.toString());
    final storeNew = await initStore(
      cacheNew,
      storageNew,
      existingUser: existingUser,
      existingState: storeExisting,
    );

    setState(() {
      cache = cacheNew;
      storage = storageNew;
      store = storeNew;
    });

    // wipe unauthenticated storage
    if (user != null) {
      printInfo('[onContextChanged] Deleting default cache');
      await deleteCache();
      await deleteStorage();
    } else {
      // delete cache data if removing context / account (context is not default)
      printInfo('[onContextChanged] Deleting old cache ${contextOld.current}');
      await deleteCache(context: contextOld.current);
      await deleteStorage(context: contextOld.current);
    }

    // reinitialize and start new store listeners
    onInitListeners();
    onStartListeners();

    // reinitialize state of current context user
    storeNew.state.authStore.authObserver?.add(
      user,
    );

    storeNew.dispatch(SetGlobalLoading(loading: false));
  }

  onAuthStateChanged(User? user) async {
    final allContexts = await loadContexts();
    final defaultScreen = defaultHome.runtimeType;

    // No user is present and no contexts are availble to jump to
    if (user == null && allContexts.isEmpty && defaultScreen == HomeScreen) {
      defaultHome = IntroScreen();
      return NavigationService.clearTo(NavigationPaths.intro, context);
    }

    // No user is present during auth state change, but other contexts exist
    if (user == null && allContexts.isNotEmpty && defaultScreen == HomeScreen) {
      return NavigationService.clearTo(NavigationPaths.home, context);
    }

    // New user is found and previously was in an unauthenticated state
    if (user != null && user.accessToken != null && defaultScreen == IntroScreen) {
      defaultHome = HomeScreen();
      return NavigationService.clearTo(NavigationPaths.home, context);
    }

    // New user has been authenticated during an existing authenticated session
    // NOTE: skips users without accessTokens because that would mean its a multiaccount switch
    if (user != null &&
        user.accessToken != null &&
        user.accessToken!.isNotEmpty &&
        defaultScreen == HomeScreen) {
      return NavigationService.clearTo(NavigationPaths.settings, context);
    }
  }

  onAlertsChanged(Alert alert) {
    Color? color;

    switch (alert.type) {
      case 'error':
        color = Colors.red;
        break;
      case 'warning':
        color = Colors.red;
        break;
      case 'success':
        color = Colors.green;
        break;
      case 'info':
      default:
        color = Colors.grey;
    }

    final alertMessage = alert.message ?? alert.error ?? 'Unknown Error Occurred';

    globalScaffold.currentState?.showSnackBar(SnackBar(
      backgroundColor: color,
      content: Text(
        alertMessage,
        style: Theme.of(context).textTheme.subtitle1?.copyWith(color: Colors.white),
      ),
      duration: alert.duration,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          globalScaffold.currentState?.removeCurrentSnackBar();
        },
      ),
    ));
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
          startLocale: Locale(formatLanguageCode(store.state.settingsStore.language)),
          fallbackLocale: Locale(LangCodes.en),
          supportedLocales: const [
            Locale(LangCodes.en),
            Locale(LangCodes.ru),
            Locale(LangCodes.pl),
          ],
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
