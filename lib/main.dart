import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Library Implimentations
import 'package:Tether/global/libs/hive.dart';

// Redux - State Managment - "store"
import 'package:Tether/domain/index.dart';

// Intro
import 'package:Tether/views/login.dart';
import 'package:Tether/views/signup/index.dart';
import 'package:Tether/views/homesearch.dart';
import 'package:Tether/views/intro/index.dart';
import 'package:Tether/views/loading.dart';

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/settings.dart';

// Chat
import 'package:Tether/views/chats/index.dart';

// Styling
import 'package:Tether/global/themes.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  _enablePlatformOverrideForDesktop();
  await DotEnv().load(kReleaseMode ? '.env' : '.env.debug');
  runApp(Tether());
}

class Tether extends StatefulWidget {
  @override
  TetherState createState() => TetherState();
}

class TetherState extends State<Tether> with WidgetsBindingObserver {
  @override
  void initState() {
    initStorage();
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  // TODO: REMOVE WHEN DEPLOYED
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('state = $state');
  }

  @override
  void deactivate() {
    closeStorage();
    WidgetsBinding.instance.removeObserver(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return StoreProvider<AppState>(
        store: store,
        child: StoreConnector<AppState, dynamic>(
            converter: (store) => store.state.settingsStore.theme,
            builder: (context, theme) {
              return MaterialApp(
                title: 'Tether',
                theme: Themes.getThemeFromKey(theme),
                initialRoute: '/intro',
                routes: <String, WidgetBuilder>{
                  '/intro': (BuildContext context) =>
                      IntroScreen(title: 'Intro'),
                  '/login': (BuildContext context) => Login(title: 'Login'),
                  '/search_home': (BuildContext context) =>
                      HomeSearchScreen(title: 'Find Your Homeserver'),
                  '/signup': (BuildContext context) => Signup(title: 'Signup'),
                  '/home': (BuildContext context) =>
                      HomeScreen(title: 'Tether'),
                  '/chats': (BuildContext context) => Chats(),
                  '/settings': (BuildContext context) =>
                      SettingsScreen(title: 'Settings'),
                  '/loading': (BuildContext context) =>
                      Loading(title: 'Loading'),
                },
              );
            }));
  }
}
