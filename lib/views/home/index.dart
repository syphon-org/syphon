import 'package:Tether/domain/user/selectors.dart';
import 'package:Tether/global/assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/rooms/model.dart';
import 'package:Tether/domain/rooms/selectors.dart';
import 'package:Tether/domain/rooms/actions.dart';

// View And Styling
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/dimensions.dart';

enum Overflow { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatelessWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  @protected
  onNavigateToDraft(context) {
    Navigator.pushNamed(context, '/draft');
  }

  Widget buildConversationList(List<Room> rooms, BuildContext context) {
    if (rooms.length > 0) {
      return ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: rooms.length,
        itemBuilder: (BuildContext context, int index) {
          // GestureDetector w/ animation
          return InkWell(
              onTap: () => Navigator.pushNamed(
                    context,
                    '/home/messages',
                    arguments: MessageArguments(
                      title: rooms[index].name.toString(),
                      photo: 'https://google.com/image',
                    ),
                  ),
              child: Container(
                child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.grey,
                              child: Text(
                                rooms[index].name.substring(0, 2).toUpperCase(),
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                          Text(
                            rooms[index].name.toString(),
                            style: TextStyle(fontSize: 20),
                          ),
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
        titleSpacing: 24.0,
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
                      child: buildConversationList(rooms(state), context),
                    )
                  ]);
            }),
      ),
      floatingActionButton: StoreConnector<AppState, dynamic>(
        converter: (store) => () => store.dispatch(addRoom()),
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
