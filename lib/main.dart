// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Package imports:
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/platform.dart';
import 'package:syphon/storage/index.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/events/messages/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/views/home/index.dart';
import 'package:syphon/views/intro/index.dart';
import 'package:syphon/views/navigation.dart';

void main() async {
  WidgetsFlutterBinding();
  WidgetsFlutterBinding.ensureInitialized();

  // init platform specific code
  await initPlatformDependencies();

  // init hot cache and cold storage
  final cache = await initCache();

  // init cold storage and load backup cache
  final storage = await initStorage();

  // init redux store
  final store = await initStore(cache, storage);

  // init app
  runApp(Syphon(store, cache, storage));
}

class Syphon extends StatefulWidget {
  final Database cache;
  final Database storage;
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
  final Database cache;
  final Database storage;
  final Store<AppState> store;
  final GlobalKey<ScaffoldState> globalScaffold = GlobalKey<ScaffoldState>();

  Widget defaultHome = Home();
  StreamSubscription? alertsListener;

  SyphonState(
    this.store,
    this.cache,
    this.storage,
  );

  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();

    // set system status bar to match theme.
    // sadly the navbar doesn't play nicely with just being transparent
    // so will also be updated on theme change
    final currentTheme = store.state.settingsStore.theme;
    initSystemTheme(currentTheme, statusTransparent: false);

    store.dispatch(initDeepLinks());
    store.dispatch(initClientSecret());
    store.dispatch(startAuthObserver());
    store.dispatch(startAlertsObserver());

    // mutate messages
    store.dispatch(mutateMessagesAll());

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = Intro();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
        final currentTheme = store.state.settingsStore.theme;
        initSystemTheme(currentTheme, statusTransparent: false);
        break;
      case AppLifecycleState.inactive:
        break;
        break;
      case AppLifecycleState.paused:
        store.dispatch(setBackgrounded(true));
        break;
      case AppLifecycleState.detached:
        store.dispatch(setBackgrounded(true));
        break;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @protected
  void onMounted() {
    // init auth listener
    store.state.authStore.onAuthStateChanged.listen((user) {
      if (user == null && defaultHome.runtimeType == Home) {
        defaultHome = Intro();
        NavigationService.clearTo('/intro', context);
      } else if (user != null &&
          user.accessToken != null &&
          defaultHome.runtimeType == Intro) {
        // Default Authenticated App Home
        defaultHome = Home();
        NavigationService.clearTo('/home', context);
      }
    });

    // init alerts listener
    alertsListener = store.state.alertsStore.onAlertsChanged.listen((alert) {
      var color;

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

      final alertMessage =
          alert.message ?? alert.error ?? 'Unknown Error Occured';

      globalScaffold.currentState?.showSnackBar(SnackBar(
        backgroundColor: color,
        content: Text(
          alertMessage,
          style: Theme.of(context)
              .textTheme
              .subtitle1
              ?.copyWith(color: Colors.white),
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
    });
  }

  @override
  void dispose() {
    alertsListener?.cancel();
    store.dispatch(disposeDeepLinks());
    super.dispose();
  }

  @override
  void deactivate() {
    closeCache(cache);
    WidgetsBinding.instance?.removeObserver(this);
    store.dispatch(stopAuthObserver());
    store.dispatch(stopAlertsObserver());
    super.deactivate();
  }

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Testing Notifications'),
        content: Text('Payload : $payload'),
      ),
    );
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: localization.EasyLocalization(
          path: 'assets/translations',
          useOnlyLangCode: true,
          startLocale:
              Locale(formatLanguageCode(store.state.settingsStore.language)),
          fallbackLocale: Locale('en'),
          supportedLocales: [Locale('en'), Locale('ru')],
          child: StoreConnector<AppState, SettingsStore>(
            distinct: true,
            converter: (store) => store.state.settingsStore,
            builder: (context, settings) => MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              debugShowCheckedModeBanner: false,
              theme: Themes.generateCustomTheme(
                primaryColorHex: settings.primaryColor,
                accentColorHex: settings.accentColor,
                appBarColorHex: settings.appBarColor,
                fontName: settings.fontName,
                fontSize: settings.fontSize,
                themeType: settings.theme,
              ),
              navigatorKey: NavigationService.navigatorKey,
              routes: NavigationProvider.getRoutes(),
              home: defaultHome,
              builder: (context, child) => Scaffold(
                body: child,
                appBar: null,
                key: globalScaffold,
              ),
            ),
          ),
        ),
      );
}
