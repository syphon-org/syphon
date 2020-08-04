// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';
import 'package:syphon/views/widgets/modals/modal-user-details.dart';
import 'package:touchable_opacity/touchable_opacity.dart';

// Project imports:
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/events/selectors.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart' as roomSelectors;
import 'package:syphon/store/settings/chat-settings/actions.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/dialogs/dialog-color-picker.dart';

class ChatSettingsArguments {
  final String roomId;
  final String title;

  // Improve loading times
  ChatSettingsArguments({
    this.roomId,
    this.title,
  });
}

class ChatDetailsView extends StatefulWidget {
  const ChatDetailsView({Key key}) : super(key: key);

  @override
  ChatDetailsState createState() => ChatDetailsState();
}

class ChatDetailsState extends State<ChatDetailsView> {
  ChatDetailsState({Key key}) : super();

  final ScrollController scrollController = ScrollController(
    initialScrollOffset: 0,
  );

  double headerOpacity = 1;
  double headerSize = 54;
  List<User> usersList;

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

  @protected
  onShowUserDetails({
    BuildContext context,
    String roomId,
    String userId,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ModalUserDetails(
        roomId: roomId,
        userId: userId,
      ),
    );
  }

  @protected
  onShowColorPicker({
    context,
    int originalColor,
    Function onSelectColor,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => DialogColorPicker(
        title: 'Select Chat Color',
        currentColor: originalColor,
        onSelectColor: onSelectColor,
      ),
    );
  }

  @protected
  Widget buildUsersPreview(_Props props) {
    final List<User> users = props.userList;

    return ListView.builder(
      shrinkWrap: true,
      itemCount: users.length < 12 ? users.length : 12,
      scrollDirection: Axis.horizontal,
      itemBuilder: (BuildContext context, int index) {
        final user = users[index];
        return Align(
          alignment: Alignment.topLeft,
          heightFactor: 0.8,
          child: GestureDetector(
            onTap: () {
              onShowUserDetails(
                context: context,
                roomId: props.room.id,
                userId: user.userId,
              );
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              child: AvatarCircle(
                uri: user.avatarUri,
                alt: user.displayName ?? user.userId,
                size: 54,
                background: user.avatarUri != null
                    ? Colors.transparent
                    : Colours.hashedColor(user.userId),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    // Confirm this is needed in chat details
    final titlePadding = Dimensions.listTitlePaddingDynamic(width: width);
    final contentPadding = Dimensions.listPaddingDynamic(width: width);

    final ChatSettingsArguments arguments =
        ModalRoute.of(context).settings.arguments;

    final scaffordBackgroundColor =
        Theme.of(context).brightness == Brightness.light
            ? Colors.grey[200]
            : Theme.of(context).scaffoldBackgroundColor;

    return StoreConnector<AppState, _Props>(
      distinct: true,
      converter: (Store<AppState> store) => _Props.mapStateToProps(
        store,
        arguments.roomId,
      ),
      builder: (context, props) => Scaffold(
        backgroundColor: scaffordBackgroundColor,
        body: CustomScrollView(
          controller: scrollController,
          scrollDirection: Axis.vertical,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: height * 0.3,
              brightness: Theme.of(context).appBarTheme.brightness,
              automaticallyImplyLeading: false,
              titleSpacing: 0.0,
              title: Row(
                children: <Widget>[
                  Container(
                    margin: EdgeInsets.only(left: 8),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      arguments.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ),
                ],
              ),
              flexibleSpace: Hero(
                tag: "ChatAvatar",
                child: Container(
                  padding: EdgeInsets.only(top: height * 0.075),
                  color: props.roomPrimaryColor,
                  width: width,
                  child: OverflowBox(
                    minHeight: 64,
                    maxHeight: height * 0.3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: headerOpacity,
                          child: AvatarCircle(
                            size: height * 0.15,
                            uri: props.room.avatarUri,
                            alt: props.room.name,
                            background: props.room.colorDefault,
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
                    CardSection(
                      margin: EdgeInsets.only(bottom: 4),
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: titlePadding,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  child: Row(
                                    children: [
                                      Text(
                                        'Users',
                                        textAlign: TextAlign.start,
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle2,
                                      ),
                                    ],
                                  ),
                                ),
                                TouchableOpacity(
                                  onTap: () {
                                    // Navigator.pushNamed(
                                    //   context,
                                    //   '/home/chat/details/users',
                                    // );
                                  },
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
                                            '(${props.room.users.length})',
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
                          Container(
                            padding: EdgeInsets.only(
                              left: 8,
                              top: 8,
                              bottom: 8,
                            ),
                            constraints: BoxConstraints(
                              maxHeight: Dimensions.avatarSize * 1.5,
                              maxWidth: width,
                            ),
                            child: buildUsersPreview(props),
                          )
                        ],
                      ),
                    ),
                    CardSection(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: width,
                            padding: titlePadding,
                            child: Text(
                              'About',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
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
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                Text(
                                  props.room.id,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.caption,
                                ),
                                Text(
                                  props.room.type,
                                  textAlign: TextAlign.start,
                                  style: Theme.of(context).textTheme.caption,
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
                    CardSection(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Container(
                        child: Column(
                          children: [
                            Container(
                              width: width,
                              padding: contentPadding,
                              child: Text(
                                'Chat Settings',
                                textAlign: TextAlign.start,
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                            ),
                            ListTile(
                              onTap: () => onShowColorPicker(
                                context: context,
                                onSelectColor: props.onSelectPrimaryColor,
                                originalColor: props.roomPrimaryColor.value,
                              ),
                              contentPadding: contentPadding,
                              title: Text(
                                'Color',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                padding: EdgeInsets.only(right: 16),
                                child: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: props.roomPrimaryColor,
                                ),
                              ),
                            ),
                            ListTile(
                              dense: true,
                              enabled: !props.loading,
                              onTap: () {
                                props.onToggleDirectRoom();
                              },
                              contentPadding: contentPadding,
                              title: Text(
                                'Toggle Direct Room',
                                style: TextStyle(fontSize: 18.0),
                              ),
                              trailing: Container(
                                child: Switch(
                                  value: props.room.direct,
                                  onChanged: (value) {
                                    props.onToggleDirectRoom();
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CardSection(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: contentPadding,
                            child: Text(
                              'Notifications Settings',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
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
                            enabled: false,
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
                            enabled: false,
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
                        ],
                      ),
                    ),
                    CardSection(
                      child: Column(
                        children: [
                          Container(
                            width: width,
                            padding: contentPadding,
                            child: Text(
                              'Privacy and Status',
                              textAlign: TextAlign.start,
                              style: Theme.of(context).textTheme.subtitle2,
                            ),
                          ),
                          ListTile(
                            enabled: false,
                            contentPadding: contentPadding,
                            title: Text(
                              'View Encryption Key',
                              style: TextStyle(fontSize: 18.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CardSection(
                      child: Container(
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () {},
                              contentPadding: contentPadding,
                              title: Text(
                                'Leave Chat',
                                style: TextStyle(
                                  fontSize: 18.0,
                                  color: Colors.redAccent,
                                ),
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

class _Props extends Equatable {
  final Room room;
  final bool loading;
  final Color roomPrimaryColor;
  final List<Message> messages;
  final List<User> userList;

  final Function onLeaveChat;
  final Function onSelectPrimaryColor;
  final Function onToggleDirectRoom;
  final Function onViewEncryptionKeys;

  _Props({
    @required this.room,
    @required this.userList,
    @required this.loading,
    @required this.messages,
    @required this.onLeaveChat,
    @required this.roomPrimaryColor,
    @required this.onSelectPrimaryColor,
    @required this.onToggleDirectRoom,
    @required this.onViewEncryptionKeys,
  });

  @override
  List<Object> get props => [
        room,
        messages,
        roomPrimaryColor,
        loading,
      ];

  static _Props mapStateToProps(Store<AppState> store, String roomId) => _Props(
      room: roomSelectors.room(id: roomId, state: store.state),
      loading: store.state.roomStore.loading,
      userList: List.from(
        roomSelectors.room(id: roomId, state: store.state).users.values,
      ),
      messages: latestMessages(
        roomSelectors.room(id: roomId, state: store.state).messages,
      ),
      onLeaveChat: () async {
        await store.dispatch(removeRoom(room: Room(id: roomId)));
      },
      roomPrimaryColor: () {
        final customChatSettings =
            store.state.settingsStore.customChatSettings ??
                Map<String, ChatSetting>();

        if (customChatSettings[roomId] != null) {
          return customChatSettings[roomId].primaryColor != null
              ? Color(customChatSettings[roomId].primaryColor)
              : Colors.grey;
        }

        return Colours.hashedColor(roomId);
      }(),
      onSelectPrimaryColor: (color) {
        store.dispatch(
          updateRoomPrimaryColor(roomId: roomId, color: color),
        );
      },
      onToggleDirectRoom: () {
        final room = roomSelectors.room(id: roomId, state: store.state);
        store.dispatch(toggleDirectRoom(room: room, enabled: !room.direct));
      });
}
