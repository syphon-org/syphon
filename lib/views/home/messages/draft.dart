import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/chat/selectors.dart';
import 'package:Tether/domain/chat/actions.dart';

enum Overflow { newGroup, markAllRead, inviteFriends, settings, help }

class Draft extends StatelessWidget {
  Draft({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text('TE'),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              tooltip: 'Profile',
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              print('SEARCH STUB');
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              print('SEARCH STUB');
            },
            tooltip: 'Search Messages',
          ),
          PopupMenuButton<Overflow>(
            onSelected: (Overflow result) {
              switch (result) {
                case Overflow.settings:
                  Navigator.pushNamed(context, '/settings');
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Overflow>>[
              const PopupMenuItem<Overflow>(
                value: Overflow.newGroup,
                child: Text('New Group'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.markAllRead,
                child: Text('Mark All Read'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.inviteFriends,
                child: Text('Invite Friends'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.settings,
                child: Text('Settings'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.help,
                child: Text('Help'),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            StoreConnector<AppState, int>(
              converter: (Store<AppState> store) => 0,
              builder: (context, count) {
                return Text(
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
        builder: (context, onAction) => FloatingActionButton(
            child: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            tooltip: 'Increment',
            onPressed: () => onAction()),
      ),
    );
  }
}
