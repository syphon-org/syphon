import 'package:Tether/domain/user/selectors.dart';
import 'package:Tether/global/assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/domain/rooms/selectors.dart';

// View And Styling
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/global/colors.dart';

enum Overflow { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatelessWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @protected
  onNavigateToDraft(context) {
    Navigator.pushNamed(context, '/draft');
  }

  String formatRoomName({Room room}) {
    final name = room.name;
    return name.length > 22 ? '${name.substring(0, 22)}...' : name;
  }

  String formatPreview({Room room}) {
    if (room.messages.length < 1) {
      return room.topic;
    }

    final lastMessage = room.messages[0].body;
    final shortened = lastMessage.length > 42;
    final preview = shortened
        ? lastMessage.substring(0, 42).replaceAll('\n', '')
        : lastMessage;

    return shortened ? '$preview...' : preview;
  }

  String formatSinceLastUpdate({int lastUpdateMillis}) {
    if (lastUpdateMillis == null || lastUpdateMillis == 0) return '';

    final timestamp = DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
    final sinceLastUpdate = DateTime.now().difference(timestamp);

    if (sinceLastUpdate.inDays > 6) {
      // Abbreviated month and day number - Jan 1
      return DateFormat.MMMd().format(timestamp);
    } else if (sinceLastUpdate.inDays > 0) {
      // Abbreviated weekday - Fri
      return DateFormat.E().format(timestamp);
    } else if (sinceLastUpdate.inHours > 0) {
      // Abbreviated hours since - 1h
      return '${sinceLastUpdate.inHours}h';
    } else if (sinceLastUpdate.inMinutes > 0) {
      // Abbreviated minutes since - 1m
      return '${sinceLastUpdate.inMinutes}m';
    } else if (sinceLastUpdate.inSeconds > 1) {
      // Just say now if it's been within the minute
      return 'Now';
    } else {
      return '';
    }
  }

  Widget buildChatAvatar({Room room}) {
    if (room.syncing) {
      return Container(
          margin: EdgeInsets.all(8),
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
            value: null,
          ));
    }

    if (room.avatar != null && room.avatar.data != null) {
      return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image(
            width: 52,
            height: 52,
            image: MemoryImage(room.avatar.data),
          ));
    }

    return Text(
      room.name.substring(0, 2).toUpperCase(),
      style: TextStyle(fontSize: 18, color: Colors.white),
    );
  }

  Widget buildConversationList(List<Room> rooms, BuildContext context) {
    if (rooms.length > 0) {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int index) {
          final room = rooms[index];

          // GestureDetector w/ animation
          return InkWell(
              onTap: () => Navigator.pushNamed(
                    context,
                    '/home/messages',
                    arguments: MessageArguments(
                      roomId: room.id,
                      title: room.name,
                    ),
                  ),
              child: Container(
                child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 18,
                    ),
                    child: Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            child: CircleAvatar(
                                radius: 24,
                                backgroundColor: room.avatar != null
                                    ? Colors.white70
                                    : Colors.grey,
                                child: buildChatAvatar(room: room)),
                            margin: const EdgeInsets.only(right: 12),
                          ),
                          Flexible(
                              flex: 1,
                              fit: FlexFit.tight,
                              child: Flex(
                                  direction: Axis.vertical,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          formatRoomName(room: room),
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400),
                                        ),
                                        Text(
                                          formatSinceLastUpdate(
                                              lastUpdateMillis:
                                                  room.lastUpdate),
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w100),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      formatPreview(room: room),
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ])),
                        ])),
              ));
        },
      );
    }

    return Center(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
            constraints:
                BoxConstraints(minWidth: 200, maxWidth: 400, maxHeight: 200),
            child: SvgPicture.asset(GRAPHIC_EMPTY_MESSAGES,
                semanticsLabel: 'Tiny cute monsters hidding behind foliage')),
        Container(
            margin: EdgeInsets.only(bottom: 48),
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Seems there\'s no messages yet',
              style: Theme.of(context).textTheme.title,
            ))
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 22.00,
        title: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: StoreConnector<AppState, String>(
                  converter: (store) => displayInitials(store.state),
                  builder: (context, initials) {
                    return CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Text(
                        initials.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    );
                  }),
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              tooltip: 'Profile and Settings',
            ),
          ),
          Text(title,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w100)),
        ]),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
            tooltip: 'Search Chats',
          ),
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
        alignment: Alignment.topCenter,
        child: StoreConnector<AppState, AppState>(
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
                      child: buildConversationList(
                        sortRoomsByPriority(state),
                        context,
                      ),
                    )
                  ]);
            }),
      ),
      floatingActionButton: StoreConnector<AppState, dynamic>(
        converter: (store) => () => print('Add Room Stub'),
        builder: (context, onAction) => FloatingActionButton(
            child: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            backgroundColor: PRIMARY_COLOR,
            tooltip: 'New Chat',
            onPressed: () => onNavigateToDraft(context)),
      ),
    );
  }
}
