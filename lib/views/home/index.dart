import 'package:Tether/global/assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Domain
import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/chat/model.dart';
import 'package:Tether/domain/chat/selectors.dart';
import 'package:Tether/domain/chat/actions.dart';

// View And Styling
import 'package:Tether/views/home/messages/index.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/dimensions.dart';

enum Overflow { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatelessWidget {
  Home({Key key, this.title}) : super(key: key);

  final String title;

  Widget buildConversationList(List<Chat> chats, BuildContext context) {
    if (chats.length > 0) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.vertical,
        itemCount: chats.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
              onTap: () => Navigator.pushNamed(
                    context,
                    '/home/messages',
                    arguments: MessageArguments(
                      title: chats[index].title.toString(),
                      photo: 'https://google.com/image',
                    ),
                  ),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    chats[index].title.toString(),
                    style: TextStyle(fontSize: 22.0),
                  ),
                ),
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
    double height = MediaQuery.of(context).size.height;
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Row(children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8, right: 8),
            child: IconButton(
              icon: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Text(
                  'TE',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
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
        child: StoreConnector<AppState, List<Chat>>(
            converter: (Store<AppState> store) => chats(store.state),
            builder: (context, chats) {
              return buildConversationList(chats, context);
            }),
      ),
      floatingActionButton: StoreConnector<AppState, dynamic>(
        converter: (store) => () => store.dispatch(addChat()),
        builder: (context, onAction) => FloatingActionButton(
            child: Icon(
              Icons.edit,
              color: Colors.white,
            ),
            backgroundColor: PRIMARY_COLOR,
            tooltip: 'New Chat',
            onPressed: () => onAction()),
      ),
    );
  }
}
