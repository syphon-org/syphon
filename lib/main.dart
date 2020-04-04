import 'dart:io';
import 'package:Tether/domain/alerts/actions.dart';
import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Library Implimentations
import 'package:Tether/global/libs/hive.dart';

// Redux - State Managment - "store" - IMPORT ONLY ONCE
import 'package:Tether/domain/index.dart';

// Navigation
import 'package:Tether/views/navigation.dart';
import 'package:Tether/views/intro/index.dart';
import 'package:Tether/views/home/index.dart';

// Styling
import 'package:Tether/global/themes.dart';
import 'package:redux/redux.dart';

/**
 * DESKTOP ONLY
import 'package:window_utils/window_utils.dart';
 */

// Generated Json Serializables
import 'main.reflectable.dart'; // Import generated code.

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  initializeReflectable();
  await DotEnv().load(kReleaseMode ? '.env.release' : '.env.debug');
  _enablePlatformOverrideForDesktop();

  // init cold cache (mobile only)
  if (Platform.isIOS || Platform.isAndroid) {
    Cache.hive = await initHiveStorage();
  }

  // init state cache (hot)
  final store = await initStore();

  // /**
  //  * DESKTOP ONLY
  // if (Platform.isMacOS) {
  //   print(await WindowUtils.getWindowSize());
  //   await WindowUtils.setSize(Size(720, 720));
  // }
  //  */

  // the main thing
  runApp(Tether(store: store));
}

class Tether extends StatefulWidget {
  final Store<AppState> store;
  const Tether({Key key, this.store}) : super(key: key);

  @override
  TetherState createState() => TetherState(store: store);
}

class TetherState extends State<Tether> with WidgetsBindingObserver {
  final Store<AppState> store;
  Widget defaultHome = Home(title: 'Tether');
  TetherState({this.store});

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

    final currentUser = store.state.userStore.user;
    final authed = currentUser.accessToken != null;

    if (!authed) {
      defaultHome = Intro();
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      onMounted();
    });
  }

  // INFO: Used to check when the app is backgrounded
  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   print('state = $state');
  // }

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
    store.state.userStore.onAuthStateChanged.listen((user) {
      if (user == null && defaultHome.runtimeType == Home) {
        defaultHome = Intro();
        NavigationService.clearTo('/intro', context);
      } else if (user != null &&
          user.accessToken != null &&
          defaultHome.runtimeType == Intro) {
        // Default Authenticated App Home
        defaultHome = Home(title: 'Tether');
        NavigationService.clearTo('/home', context);

        // Default Authenticated Services
        initNotifications(
          onSelectNotification: onSelectNotification,
        );
      }
    });
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: StoreConnector<AppState, ThemeType>(
          distinct: true,
          converter: (store) => store.state.settingsStore.theme,
          builder: (context, theme) => MaterialApp(
            title: 'Tether',
            theme: Themes.generateCustomTheme(themeType: theme),
            navigatorKey: NavigationService.navigatorKey,
            routes: NavigationProvider.getRoutes(store),
            home: defaultHome,
          ),
        ),
      );
}
