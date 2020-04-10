import 'package:Tether/domain/rooms/events/actions.dart';
import 'package:Tether/domain/rooms/events/model.dart';
import 'package:Tether/domain/rooms/events/selectors.dart';
import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/selectors.dart' as roomSelectors;

import 'package:Tether/views/widgets/menu.dart';

class ChatSettingsArguments {
  final String roomId;
  final String title;

  // Improve loading times
  ChatSettingsArguments({
    this.roomId,
    this.title,
  });
}

class ChatSettings extends StatelessWidget {
  ChatSettings({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Static horizontal: 16, vertical: 8
    final contentPadding = EdgeInsets.symmetric(
      horizontal: width * 0.08,
      vertical: height * 0.005,
    );

    final ChatSettingsArguments arguments =
        ModalRoute.of(context).settings.arguments;

    final sectionBackgroundColor =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(BASICALLY_BLACK)
            : Colors.grey;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStoreToProps(
        store,
        arguments.roomId,
      ),
      builder: (context, props) => Scaffold(
        appBar: AppBar(
          brightness: Brightness.dark, // TOOD: this should inherit from theme
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
                radius: 24,
                backgroundColor: props.room.avatar != null
                    ? Colors.transparent
                    : Colors.grey,
                child: buildChatAvatar(room: props.room),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              tooltip: 'Profile and settings',
            ),
            Text(
              arguments.title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
            ),
          ]),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: sectionBackgroundColor),
                child: Column(
                  children: [
                    Container(
                      child: Text('Shared Media'),
                    ),
                    ListTile(
                      onTap: () {},
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.chat,
                            size: 28,
                          )),
                      title: Text(
                        'SMS and MMS',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text('testing'),
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.notifications,
                            size: 28,
                          )),
                      title: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text('testing'),
                    ),
                    ListTile(
                      onTap: () {},
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.lock,
                            size: 28,
                          )),
                      title: Text(
                        'Privacy',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text(
                        'Screen Lock Off, Registration Lock Off',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: sectionBackgroundColor),
                child: Column(
                  children: [
                    Container(
                      child: Text('Shared Media'),
                    ),
                    ListTile(
                      onTap: () {},
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.chat,
                            size: 28,
                          )),
                      title: Text(
                        'SMS and MMS',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text('testing'),
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.pushNamed(context, '/notifications');
                      },
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.notifications,
                            size: 28,
                          )),
                      title: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text('testing'),
                    ),
                    ListTile(
                      onTap: () {},
                      contentPadding: contentPadding,
                      leading: Container(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.lock,
                            size: 28,
                          )),
                      title: Text(
                        'Privacy',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      subtitle: Text(
                        'Screen Lock Off, Registration Lock Off',
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _Props {
  final Room room;
  final String userId;
  final List<Message> messages;
  final bool roomsLoading;

  final Function onSendMessage;

  _Props({
    @required this.room,
    @required this.userId,
    @required this.messages,
    @required this.roomsLoading,
    @required this.onSendMessage,
  });

  static _Props mapStoreToProps(Store<AppState> store, String roomId) => _Props(
        userId: store.state.userStore.user.userId,
        room: roomSelectors.room(
          id: roomId,
          state: store.state,
        ),
        messages: latestMessages(
          roomSelectors.room(id: roomId, state: store.state).messages,
        ),
        roomsLoading: store.state.roomStore.loading,
        onSendMessage: ({
          String roomId,
          String body,
        }) {
          if (body != null && body.length > 1) {
            store.dispatch(sendMessage(
              body: body,
              room: store.state.roomStore.rooms[roomId],
              type: 'm.room.message',
            ));
          }
        },
      );

  @override
  int get hashCode =>
      userId.hashCode ^ messages.hashCode ^ roomsLoading.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Props &&
          runtimeType == other.runtimeType &&
          messages == other.messages &&
          userId == other.userId &&
          roomsLoading == other.roomsLoading;
}
