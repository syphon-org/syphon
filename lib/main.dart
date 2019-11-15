import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/settings.dart';

// Chat
import 'package:Tether/views/chat/index.dart';

// Styling
import 'package:Tether/global/themes.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  _enablePlatformOverrideForDesktop();
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
                  '/login': (BuildContext context) =>
                      LoginScreen(title: 'Login'),
                  '/search_home': (BuildContext context) =>
                      HomeSearchScreen(title: 'Find Your Homeserver'),
                  '/signup': (BuildContext context) => Signup(title: 'Signup'),
                  '/home': (BuildContext context) =>
                      HomeScreen(title: 'Tether'),
                  '/chat': (BuildContext context) => ChatScreen(),
                  '/settings': (BuildContext context) =>
                      SettingsScreen(title: 'Settings'),
                },
              );
            }));
  }
}
