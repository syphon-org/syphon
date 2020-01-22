import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/model.dart';
import 'package:Tether/domain/rooms/room/model.dart';
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

  Widget buildMessageList(String roomId, BuildContext context) {
    return StoreConnector<AppState, AppState>(
      converter: (Store<AppState> store) => store.state,
      builder: (context, state) {
        final messages = room(id: roomId, state: state).messages;
        final userId = state.userStore.user.userId;
        return ListView.builder(
          scrollDirection: Axis.vertical,
          itemCount: messages.length,
          itemBuilder: (BuildContext context, int index) {
            final message = messages[index];
            // if (message.userId != userId) {
            //   return Container(
            // child: Container(
            //   padding: const EdgeInsets.symmetric(
            //     vertical: 16,
            //     horizontal: 24,
            //   ),
            //   child: Text(
            //     message.body,
            //     style: TextStyle(),
            //   ),
            // ),
            //   );
            // }

            return Flexible(
              flex: 1,
              fit: FlexFit.loose,
              child: Flex(
                direction: Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    child: Text(
                      message.body,
                      style: TextStyle(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessageArguments arguments =
        ModalRoute.of(context).settings.arguments;
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
        child: StoreConnector<AppState, bool>(
            rebuildOnChange: false,
            converter: (Store<AppState> store) => store.state.roomStore.loading,
            builder: (context, loading) {
              return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Visibility(
                        visible: loading,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: CircularProgressIndicator(
                            strokeWidth: 4.0,
                            valueColor: new AlwaysStoppedAnimation<Color>(
                              PRIMARY_COLOR,
                            ),
                            value: null,
                          ),
                        )),
                    Expanded(
                      child: buildMessageList(
                        arguments.roomId,
                        context,
                      ),
                    )
                  ]);
            }),
      ),
    );
  }
}
