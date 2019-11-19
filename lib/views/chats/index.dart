import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/chat/actions.dart';

enum Overflow { newGroup, markAllRead, inviteFriends, settings, help }

class ChatArguments {
  final String title;
  final String photo;

  ChatArguments({this.title, this.photo});
}

class Chats extends StatelessWidget {
  Chats({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    final ChatArguments arguments = ModalRoute.of(context).settings.arguments;
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context, false),
            ),
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey,
              child: Text(
                arguments.title.substring(
                    arguments.title.length - 2, arguments.title.length),
                style: TextStyle(color: Colors.white),
              ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: 'Profile and settings',
          ),
          Text(arguments.title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
        ]),
        actions: <Widget>[
          PopupMenuButton<Overflow>(
            icon: Icon(Icons.more_vert, color: Colors.white),
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
      body: Align(
        alignment: Alignment.topRight,
        child: Column(
          children: <Widget>[
            Text(
              arguments.title,
            ),
          ],
        ),
      ),
      floatingActionButton: StoreConnector<AppState, dynamic>(
        converter: (store) => () => store.dispatch(addChat()),
        builder: (context, onAction) => FloatingActionButton(
            child: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            backgroundColor: Colors.grey,
            tooltip: 'Increment',
            onPressed: () => onAction()),
      ),
    );
  }
}
