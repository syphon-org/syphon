import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/model.dart';
import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/global/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/actions.dart';
import 'package:redux/redux.dart';

enum Overflow {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications
}

class MessageArguments {
  final String roomId;
  final String title;
  final String photo;

  // Improve loading times
  MessageArguments({
    this.roomId,
    this.title,
    this.photo,
  });
}

class Messages extends StatelessWidget {
  Messages({Key key, this.title}) : super(key: key);

  final String title;

  Widget buildMessageList(List<Event> messages, BuildContext context) {
    return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          final message = messages[index];
          return Container(
              child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  child: Text(
                    message.body,
                  )));
        });
  }

  @override
  Widget build(BuildContext context) {
    final MessageArguments arguments =
        ModalRoute.of(context).settings.arguments;
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
                arguments.title.substring(0, 2).toUpperCase(),
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
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Overflow>>[
              const PopupMenuItem<Overflow>(
                value: Overflow.search,
                child: Text('Search'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.allMedia,
                child: Text('All Media'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.chatSettings,
                child: Text('Chat Settings'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.inviteFriends,
                child: Text('Invite Friends'),
              ),
              const PopupMenuItem<Overflow>(
                value: Overflow.muteNotifications,
                child: Text('Mute Notifications'),
              ),
            ],
          )
        ],
      ),
      body: Align(
        alignment: Alignment.topRight,
        child: StoreConnector<AppState, AppState>(
            rebuildOnChange: false,
            converter: (Store<AppState> store) => store.state,
            builder: (context, state) {
              return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Visibility(
                        visible: state.roomStore.loading,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(
                            strokeWidth: 4.0,
                            valueColor: new AlwaysStoppedAnimation<Color>(
                                PRIMARY_COLOR),
                            value: null,
                          ),
                        )),
                    Expanded(
                      child: buildMessageList(
                          room(
                            state: state,
                            id: arguments.roomId,
                          ).messages,
                          context),
                    )
                  ]);
            }),
      ),
    );
  }
}
