import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';

import 'package:Tether/domain/chat/selectors.dart';

import 'package:Tether/domain/chat/actions.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            StoreConnector<AppState, int>(
              converter: (Store<AppState> store) => counter(store.state),
              builder: (context, count) {
                return new Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.display1,
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: StoreConnector<AppState, dynamic>(
        converter: (store) => () => store.dispatch(incrementCounter()),
        builder: (context, onPress) => FloatingActionButton(
            child: Icon(Icons.add),
            tooltip: 'Increment',
            onPressed: () => onPress()),
      ),
    );
  }
}
