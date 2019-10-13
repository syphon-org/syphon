import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Redux - State Managment - "store"
import 'package:Tether/domain/index.dart';

// Views
import 'package:Tether/views/home.dart';
import 'package:Tether/views/settings.dart';

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
        child: MaterialApp(
          title: 'Tether',
          theme: Themes.getThemeFromKey(store.state.settingsStore.theme),
          initialRoute: '/',
          routes: <String, WidgetBuilder>{
            '/': (BuildContext context) => Home(title: 'Tether'),
            '/settings': (BuildContext context) => Settings(title: 'Settings')
          },
        ));
  }
}
