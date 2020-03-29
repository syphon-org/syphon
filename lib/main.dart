import 'dart:io';
import 'package:Tether/domain/alerts/actions.dart';
import 'package:Tether/domain/user/actions.dart';
import 'package:Tether/views/home/settings/appearance.dart';
import 'package:Tether/views/navigation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Library Implimentations
import 'package:Tether/global/libs/hive.dart';

// Redux - State Managment - "store" - IMPORT ONLY ONCE
import 'package:Tether/domain/index.dart';

// Intro
import 'package:Tether/views/login/index.dart';
import 'package:Tether/views/signup/index.dart';
import 'package:Tether/views/homesearch.dart';
import 'package:Tether/views/intro/index.dart';
import 'package:Tether/views/loading.dart';

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/profile/index.dart';
import 'package:Tether/views/home/settings/index.dart';

// Messages
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/views/home/messages/draft.dart';

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

  await DotEnv().load(kReleaseMode ? '.env' : '.env.debug');
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
        defaultHome = Home(title: 'Tether');
        NavigationService.clearTo('/home', context);
      }
    });
  }

  // Store should not need to be passed to a widget to affect
  // lifecycle widget functions
  @override
  Widget build(BuildContext context) => StoreProvider<AppState>(
        store: store,
        child: StoreConnector<AppState, dynamic>(
          converter: (store) => store.state.settingsStore.theme,
          builder: (context, theme) => MaterialApp(
            title: 'Tether',
            theme: Themes.getThemeFromKey(theme),
            navigatorKey: NavigationService.navigatorKey,
            home: defaultHome,
            routes: <String, WidgetBuilder>{
              '/intro': (BuildContext context) => Intro(),
              '/login': (BuildContext context) => Login(store: store),
              '/search_home': (BuildContext context) => HomeSearch(
                    title: 'Find Your Homeserver',
                    store: store,
                  ),
              '/signup': (BuildContext context) => Signup(
                    title: 'Signup',
                    store: store,
                  ),
              '/home': (BuildContext context) => Home(
                    title: 'Tether',
                  ),
              '/draft': (BuildContext context) => Draft(),
              '/profile': (BuildContext context) => Profile(),
              '/home/messages': (BuildContext context) => Messages(),
              '/appearance': (BuildContext context) => ApperanceScreen(
                    title: 'Appearance',
                  ),
              '/settings': (BuildContext context) => SettingsScreen(
                    title: 'Settings',
                  ),
              '/loading': (BuildContext context) => Loading(
                    title: 'Loading',
                  ),
            },
          ),
        ),
      );
}
