import 'dart:async';

import 'package:Tether/domain/rooms/room/selectors.dart';
import 'package:Tether/domain/user/model.dart';
import 'package:Tether/domain/user/selectors.dart';
import 'package:Tether/global/assets.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/room/model.dart';
import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/global/formatters.dart';

// View And Styling
import 'package:Tether/views/widgets/menu.dart';
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/global/colors.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatelessWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @protected
  onNavigateToDraft(context) {
    Navigator.pushNamed(context, '/home/groups/search');
  }

  Widget buildChatList(List<Room> rooms, BuildContext context) {
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
                        room.avatar != null ? Colors.transparent : Colors.grey,
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
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            formatTimestamp(
                              lastUpdateMillis: room.lastUpdate,
                            ),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w100),
                          ),
                        ],
                      ),
                      Text(
                        formatPreview(room: room),
                        style: TextStyle(fontSize: 12, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) => Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            brightness: Brightness.dark,
            titleSpacing: 18.00,
            title: Row(children: <Widget>[
              Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Text(
                      displayInitials(props.currentUser).toUpperCase(),
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  tooltip: 'Profile and Settings',
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
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
                    case Options.newGroup:
                      Navigator.pushNamed(context, '/home/groups/search');
                      break;
                    default:
                      break;
                  }
                },
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<Options>>[
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
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
                    child: Stack(
                      children: [
                        Positioned(
                          // red box
                          child: Visibility(
                            visible: props.loadingRooms,
                            child: Container(
                                child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                RefreshProgressIndicator(
                                  strokeWidth: 2.0,
                                  valueColor: new AlwaysStoppedAnimation<Color>(
                                    PRIMARY_COLOR,
                                  ),
                                  value: null,
                                ),
                              ],
                            )),
                          ),
                        ),
                        buildChatList(
                          sortedPrioritizedRooms(props.rooms),
                          context,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FabCircularMenu(
            key: Key('FabCircleMenu'),
            fabSize: 58,
            fabElevation: 4.0,
            fabMargin: EdgeInsets.all(16),
            fabOpenIcon: Icon(
              Icons.widgets,
              color: Colors.white,
            ),
            fabCloseIcon: Icon(
              Icons.close,
              color: Colors.white,
            ),
            fabColor: Theme.of(context).accentColor,
            ringDiameter: MediaQuery.of(context).size.width * 0.66,
            ringColor: Theme.of(context).accentColor.withAlpha(144),
            animationDuration: Duration(milliseconds: 275),
            children: [
              FloatingActionButton(
                heroTag: 'fab3',
                child: Icon(
                  Icons.edit,
                  // Icons.widgets,
                  color: Colors.white,
                ),
                tooltip: 'Direct Message',
                onPressed: () => onNavigateToDraft(context),
              ),
              FloatingActionButton(
                heroTag: 'fab2',
                child: Icon(
                  Icons.add,
                  // Icons.widgets,
                  color: Colors.white,
                ),
                tooltip: 'Create Chat Or Group',
                onPressed: () => onNavigateToDraft(context),
              ),
              FloatingActionButton(
                heroTag: 'fab1',
                child: Icon(
                  Icons.search,
                  // Icons.widgets,
                  color: Colors.white,
                ),
                tooltip: 'Search Groups',
                onPressed: () {
                  Navigator.pushNamed(context, '/home/groups/search');
                },
              ),
            ],
          ),
        ),
      );
}

class _Props {
  final Map rooms;
  final bool loadingRooms;
  final User currentUser;

  _Props({
    @required this.rooms,
    @required this.currentUser,
    @required this.loadingRooms,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        rooms: store.state.roomStore.rooms,
        loadingRooms: store.state.roomStore.loading,
        currentUser: store.state.userStore.user,
      );

  @override
  int get hashCode =>
      rooms.hashCode ^ loadingRooms.hashCode ^ currentUser.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _Props &&
          runtimeType == other.runtimeType &&
          rooms == other.rooms &&
          currentUser == other.currentUser &&
          loadingRooms == other.loadingRooms;
}
