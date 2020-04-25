import 'package:Tether/store/rooms/events/actions.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/store/rooms/events/selectors.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/views/widgets/chat-avatar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/selectors.dart' as roomSelectors;

import 'package:touchable_opacity/touchable_opacity.dart';

class ChatSettingsArguments {
  final String roomId;
  final String title;

  // Improve loading times
  ChatSettingsArguments({
    this.roomId,
    this.title,
  });
}

class ChatSettingsScreen extends StatefulWidget {
  const ChatSettingsScreen({Key key}) : super(key: key);

  @override
  ChatSettingsState createState() => ChatSettingsState();
}

// https://flutter.dev/docs/development/ui/animations
class ChatSettingsState extends State<ChatSettingsScreen> {
  ChatSettingsState({Key key}) : super();

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  double headerOpacity = 1;
  double headerSize = 54;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      final height = MediaQuery.of(context).size.height;
      final minOffset = 0;
      final maxOffset = height * 0.2;
      final offsetRatio = scrollController.offset / maxOffset;

      final isOpaque = scrollController.offset <= minOffset;
      final isTransparent = scrollController.offset > maxOffset;
      final isFading = !isOpaque && !isTransparent;

      if (isFading) {
        return this.setState(() {
          headerOpacity = 1 - offsetRatio;
        });
      }

      if (isTransparent) {
        return this.setState(() {
          headerOpacity = 0;
        });
      }

      return this.setState(() {
        headerOpacity = 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Static horizontal: 16, vertical: 8
    final contentPadding = EdgeInsets.symmetric(
      horizontal: width * 0.04,
      vertical: 4,
    );

    final titlePadding = EdgeInsets.only(
      left: width * 0.04,
      right: width * 0.04,
      top: 6,
      bottom: 14,
    );

    final ChatSettingsArguments arguments =
        ModalRoute.of(context).settings.arguments;

    final sectionBackgroundColor =
        Theme.of(context).brightness == Brightness.dark
            ? const Color(BASICALLY_BLACK)
            : const Color(BACKGROUND);

    final mainBackgroundColor = Theme.of(context).brightness == Brightness.dark
        ? null
        : const Color(DISABLED_GREY);

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStoreToProps(
        store,
        arguments.roomId,
      ),
      builder: (context, props) => Scaffold(
        backgroundColor: mainBackgroundColor,
        body: CustomScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: height * 0.3,
              brightness:
                  Brightness.dark, // TOOD: this should inherit from theme
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
                Text(
                  arguments.title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w100,
                  ),
                ),
              ]),
              flexibleSpace: Hero(
                tag: "ChatAvatar",
                child: Container(
                  padding: EdgeInsets.only(top: height * 0.05),
                  color: props.roomColorPlaceholder,
                  width: width, // TODO: use flex, i'm rushing
                  child: OverflowBox(
                    minHeight: 64,
                    maxHeight: height * 0.25,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: headerOpacity,
                          child: buildChatHero(
                            room: props.room,
                            size: height * 0.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
                delegate: SliverChildListDelegate([
              Container(
                padding: EdgeInsets.only(bottom: 12),
                child: Column(
                  children: <Widget>[
                    Card(
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      margin: EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          Container(
                            width: width, // TODO: use flex, i'm rushing
                            padding: titlePadding,
                            // decoration: BoxDecoration(
                            //   border: Border.all(width: 1, color: Colors.white),
                            // ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Users',
                                        textAlign: TextAlign.start,
                                        style: TextStyle(),
                                      ),
                                    ],
                                  ),
                                ),
                                TouchableOpacity(
                                  onTap: () {},
                                  activeOpacity: 0.4,
                                  child: Container(
                                    padding: EdgeInsets.only(
                                        left: 24, right: 4, top: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          'See all users',
                                          textAlign: TextAlign.start,
                                          style: TextStyle(),
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 4),
                                          child: Text(
                                            '(10)',
                                            textAlign: TextAlign.start,
                                            style: TextStyle(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                          ListTile(
                            onTap: () {
                              print('testing');
                            },
                            contentPadding: contentPadding,
                            leading: Container(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.chat,
                                  size: 28,
                                )),
                            title: Text(
                              'TODO: list user avai here',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: titlePadding,
                              // decoration: BoxDecoration(
                              //   border: Border.all(width: 1, color: Colors.white),
                              // ),
                              child: Text(
                                'About',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                            ),
                            Container(
                              padding: contentPadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    props.room.name,
                                    textAlign: TextAlign.start,
                                    style:
                                        Theme.of(context).textTheme.headline6,
                                  ),
                                  Visibility(
                                    visible: props.room.topic != null &&
                                        props.room.topic.length > 0,
                                    maintainSize: false,
                                    child: Container(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(props.room.topic,
                                          style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: titlePadding,
                              child: Text(
                                'Chat Settings',
                                textAlign: TextAlign.start,
                                style: TextStyle(),
                              ),
                            ),
                            ListTile(
                              dense: true,
                              onTap: () {
                                print('testing');
                              },
                              contentPadding: contentPadding,
                              title: Text(
                                'Mute conversation',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                child: Switch(
                                  value: false,
                                  onChanged: (value) {
                                    // TODO: also prevent updates from pushing the chat up in home
                                    // TODO: prevent notification if room id exists in this setting
                                  },
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: () {
                                print('testing');
                              },
                              contentPadding: contentPadding,
                              title: Text(
                                'Notification Sound',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Default (Argon)',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Vibrate',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Default',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Color',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.only(right: 6),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: props.roomColorPlaceholder,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: titlePadding,
                              child: Text(
                                'Call Settings',
                                textAlign: TextAlign.start,
                                style: TextStyle(),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Mute Notifications',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                child: Switch(
                                  value: false,
                                  onChanged: (value) {
                                    // TODO: prevent notification if room id exists in this setting
                                  },
                                ),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Notification Sound',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Default',
                                  style: TextStyle(fontSize: 18.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 4),
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      child: Container(
                        padding: EdgeInsets.only(top: 12),
                        child: Column(
                          children: [
                            Container(
                              width: width, // TODO: use flex, i'm rushing
                              padding: titlePadding,
                              child: Text(
                                'Privacy and Status',
                                textAlign: TextAlign.start,
                                style: TextStyle(),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'View Encryption Key',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Export Key',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Generate New Key',
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      elevation: 0.5,
                      color: sectionBackgroundColor,
                      margin: EdgeInsets.symmetric(vertical: 4),
                      child: Container(
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Delete All Messages',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.redAccent),
                              ),
                            ),
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Leave group',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ])),
          ],
        ),
      ),
    );
  }
}

class _Props {
  final Room room;
  final String userId;
  final Color roomColorPlaceholder;
  final List<Message> messages;
  final bool roomsLoading;

  final Function onSendMessage;

  _Props({
    @required this.room,
    @required this.userId,
    @required this.messages,
    @required this.roomColorPlaceholder,
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
        roomColorPlaceholder:
            Colors.grey ?? Color(store.state.settingsStore.accentColor),
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
