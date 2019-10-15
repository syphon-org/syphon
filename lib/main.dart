import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Redux - State Managment - "store"
import 'package:Tether/domain/index.dart';

// Intro
import 'package:Tether/views/intro/login.dart';
import 'package:Tether/views/intro/signup.dart';

// Home
import 'package:Tether/views/home/index.dart';
import 'package:Tether/views/home/settings.dart';

// Chat
import 'package:Tether/views/chat/index.dart';

// Styling
import 'package:Tether/domain/settings/model.dart';

void _enablePlatformOverrideForDesktop() {
  if (!kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux)) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() {
  _enablePlatformOverrideForDesktop();
  runApp(Tether());
}

class Tether extends StatelessWidget {
  // This widget is the root of your application.
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
                initialRoute: '/login',
                routes: <String, WidgetBuilder>{
                  '/login': (BuildContext context) =>
                      LoginScreen(title: 'Login'),
                  '/signup': (BuildContext context) =>
                      SignupScreen(title: 'Signup'),
                  '/home': (BuildContext context) =>
                      HomeScreen(title: 'Tether'),
                  '/chat': (BuildContext context) => ChatScreen(),
                  '/settings': (BuildContext context) =>
                      SettingsScreen(title: 'Settings')
                },
              );
            }));
  }
}
