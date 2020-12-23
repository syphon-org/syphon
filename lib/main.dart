// Dart imports:
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

// Flutter imports:
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:easy_localization/easy_localization.dart' as localization;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider_linux/path_provider_linux.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:sembast/sembast.dart';
import 'package:syphon/global/cache/index.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/storage/index.dart';

// Project imports:
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:syphon/views/home/index.dart';
import 'package:syphon/views/intro/index.dart';
import 'package:syphon/views/navigation.dart';

void main() async {
  WidgetsFlutterBinding();
  WidgetsFlutterBinding.ensureInitialized();

  // load correct environment configurations
  await DotEnv().load(kReleaseMode ? '.env.release' : '.env.debug');

  // disable debugPrint when in release mode
  if (kReleaseMode) {
    debugPrint = (String message, {int wrapWidth}) {};
    printDebug = (String message, {String title}) {};
    printInfo = (String message, {String title}) {};
  }

  // init platform overrides for compatability with dart libs
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }

  if (Platform.isLinux) {
    PathProviderLinux.register();
    final directory = await getApplicationSupportDirectory();
    printInfo('[linux] ${directory.path}');

    open.overrideFor(OperatingSystem.linux, () {
      final appDir = File(Platform.script.toFilePath()).parent;
      final olmDir = File(path.join(appDir.path, '/lib/libolm.so.3'));
      return DynamicLibrary.open(olmDir.path);
    });
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
    printDebug('[main] background service started $backgroundSyncStatus');
  }

  // init hot cache and cold storage
  final cache = await initCache();

  // init cold storage and load to data
  final storage = await initStorage();

  // init redux store
  final store = await initStore(cache, storage);

  // init hot cache and start
  runApp(Syphon(store: store, cache: cache, storage: storage));
}

class Syphon extends StatefulWidget {
  final Database cache;
  final Database storage;
  final Store<AppState> store;

  const Syphon({
    Key key,
    this.store,
    this.cache,
    this.storage,
  }) : super(key: key);

  @override
  SyphonState createState() => SyphonState(
        store: store,
        cache: cache,
        storage: storage,
      );
}

class SyphonState extends State<Syphon> with WidgetsBindingObserver {
  final Database cache;
  final Database storage;
  final Store<AppState> store;
  final GlobalKey<ScaffoldState> globalScaffold = GlobalKey<ScaffoldState>();

  Widget defaultHome = Home();
  StreamSubscription alertsListener;

  SyphonState({
    this.store,
    this.cache,
    this.storage,
  });

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    store.dispatch(startAuthObserver());
    store.dispatch(startAlertsObserver());

    final currentUser = store.state.authStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = Intro();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    onMounted();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.resumed:
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

      globalScaffold.currentState.showSnackBar(SnackBar(
        backgroundColor: color,
        content: Text(
          alertMessage,
          style: Theme.of(context)
              .textTheme
              .subtitle1
              .copyWith(color: Colors.white),
        ),
        duration: alert.duration,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            globalScaffold.currentState.removeCurrentSnackBar();
          },
        ),
      ));
    });
  }

  @override
  void dispose() {
    if (alertsListener != null) {
      alertsListener.cancel();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    closeCache(cache);
    WidgetsBinding.instance.removeObserver(this);
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
