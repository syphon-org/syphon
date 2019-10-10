import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:flutter_redux/flutter_redux.dart';

// Redux - State Managment
import 'package:Tether/domain/index.dart';

// Views
import 'package:Tether/views/home.dart';

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
  final store = new Store<AppState>(
    appStateReducer,
    initialState: new AppState(),
    middleware: [thunkMiddleware],
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new StoreProvider<AppState>(
        store: store,
        child: MaterialApp(
          title: 'Tether',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: Home(title: 'Tether'),
        ));
  }
}
