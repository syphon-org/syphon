import 'dart:async';

import 'package:Tether/domain/rooms/room/selectors.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:Tether/global/assets.dart';
import 'package:Tether/global/widgets/menu.dart';
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
import 'package:Tether/global/formatters.dart';

// View And Styling
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/global/colors.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatelessWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @protected
  onNavigateToDraft(context) {
    Navigator.pushNamed(context, '/draft');
  }

  Widget buildChatAvatar({Room room}) {
    if (room.syncing) {
      return Container(
        margin: EdgeInsets.all(8),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),
          value: null,
        ),
      );
    }

    if (room.avatar != null && room.avatar.data != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Image(
          width: 52,
          height: 52,
          image: MemoryImage(room.avatar.data),
        ),
      );
    }

    return Text(
      room.name.substring(0, 2).toUpperCase(),
      style: TextStyle(fontSize: 18, color: Colors.white),
    );
  }

  Widget buildConversationList(List<Room> rooms, BuildContext context) {
    if (rooms.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              minWidth: 200,
              maxWidth: 400,
              maxHeight: 200,
            ),
            child: SvgPicture.asset(
              GRAPHIC_EMPTY_MESSAGES,
              semanticsLabel: 'Tiny cute monsters hidding behind foliage',
            ),
          ),
          Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'Seems there\'s no messages yet',
                style: Theme.of(context).textTheme.headline6,
              ))
        ],
      ));
    }

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
                        backgroundColor:
                            room.avatar != null ? Colors.white70 : Colors.grey,
                        child: buildChatAvatar(room: room),
                      ),
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  formatRoomName(room: room),
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w400),
                                ),
                                Text(
                                  formatTimestamp(
                                    lastUpdateMillis: room.lastUpdate,
                                  ),
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
                          ]),
                    ),
                  ])),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        brightness: Brightness.dark,
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
          RoundedPopupMenu<Options>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (Options result) {
              switch (result) {
                case Options.settings:
                  Navigator.pushNamed(context, '/settings');
                  break;
                default:
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Options>>[
              const PopupMenuItem<Options>(
                value: Options.newGroup,
                child: Text('New Group'),
              ),
              const PopupMenuItem<Options>(
                value: Options.markAllRead,
                child: Text('Mark All Read'),
              ),
              const PopupMenuItem<Options>(
                value: Options.inviteFriends,
                child: Text('Invite Friends'),
              ),
              const PopupMenuItem<Options>(
                value: Options.settings,
                child: Text('Settings'),
              ),
              const PopupMenuItem<Options>(
                value: Options.help,
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
                      child: RefreshIndicator(
                        onRefresh: () {
                          print('STUB REFRESH');
                          return Future.delayed(
                            const Duration(milliseconds: 3000),
                            () {
                              return 'done';
                            },
                          );
                        },
                        child: buildConversationList(
                          sortRoomsByPriority(state),
                          context,
                        ),
                      ),
                    ),
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
            tooltip: 'New Chat',
            onPressed: () => onNavigateToDraft(context)),
      ),
    );
  }
}
