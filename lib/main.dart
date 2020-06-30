import 'dart:io';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/settings/state.dart';
import 'package:syphon/store/auth/actions.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Library Implimentations
import 'package:syphon/global/libs/hive/index.dart';

// Redux - State Managment - "store" - IMPORT ONLY ONCE
import 'package:syphon/store/index.dart';

// Navigation
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/intro/index.dart';
import 'package:syphon/views/home/index.dart';

// Styling
import 'package:syphon/global/themes.dart';
import 'package:redux/redux.dart';

/**
 * DESKTOP ONLY
import 'package:window_utils/window_utils.dart';
 */

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  WidgetsFlutterBinding();
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load(kReleaseMode ? '.env.release' : '.env.debug');

  bool isInRelease = true;

  assert(() {
    isInRelease = false;
    return true;
  }());

  if (isInRelease) {
    debugPrint = (String message, {int wrapWidth}) {};
  }

  _enablePlatformOverrideForDesktop();

  // init cold cache (mobile only)
  await initHive();

  Cache.state = await openHiveState();
  Cache.sync = await openHiveSync();

  // init state cache (hot)
  final store = await initStore();

  if (Platform.isAndroid) {
    final backgroundSyncStatus = await BackgroundSync.init();
    debugPrint('[main] background service started $backgroundSyncStatus');
  }

  //  * DESKTOP ONLY
  if (Platform.isMacOS) {
    // await WindowUtils.setSize(Size(720, 720));
  }

  // the main thing
  runApp(Syphon(store: store));
}

class Syphon extends StatefulWidget {
  final Store<AppState> store;
  const Syphon({Key key, this.store}) : super(key: key);

  @override
  SyphonState createState() => SyphonState(store: store);
}

class SyphonState extends State<Syphon> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> globalScaffold = GlobalKey<ScaffoldState>();
  final Store<AppState> store;
  Widget defaultHome = Home();
  SyphonState({this.store});

  Future onSelectNotification(String payload) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Testing Notifications'),
        content: Text('Payload : $payload'),
      ),
    );
  }

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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  @override
  void deactivate() {
    closeStorage();
    WidgetsBinding.instance.removeObserver(this);
    store.dispatch(stopAuthObserver());
    store.dispatch(stopAlertsObserver());
    super.deactivate();
  }

  @protected
  void onMounted() {
    // init authenticated navigation
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
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: StoreConnector<AppState, SettingsStore>(
          distinct: true,
          converter: (store) => store.state.settingsStore,
          builder: (context, settings) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: Themes.generateCustomTheme(
              themeType: settings.theme,
              primaryColorHex: settings.primaryColor,
              accentColorHex: settings.accentColor,
            ),
            navigatorKey: NavigationService.navigatorKey,
            routes: NavigationProvider.getRoutes(store),
            home: defaultHome,
          ),
        ),
      );
}
