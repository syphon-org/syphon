// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/store/rooms/events/selectors.dart';
import 'package:url_launcher/url_launcher.dart';

// Project imports:
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/widgets/avatars/avatar-app-bar.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';
import 'package:syphon/views/widgets/containers/ring-actions.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, licenses, help }

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<Home> {
  HomeViewState({Key key}) : super();

  final GlobalKey<FabCircularMenuState> fabKey =
      GlobalKey<FabCircularMenuState>();

  Room selectedRoom;
  Map<String, Color> roomColorDefaults;

  @override
  void initState() {
    super.initState();
    roomColorDefaults = Map();
  }

  @protected
  onToggleRoomOptions({Room room}) {
    this.setState(() {
      selectedRoom = room;
    });
  }

  @protected
  onDismissMessageOptions() {
    this.setState(() {
      selectedRoom = null;
    });
  }

  @protected
  Widget buildAppBarRoomOptions({BuildContext context, _Props props}) {
    return AppBar(
      backgroundColor: Colors.grey[500],
      automaticallyImplyLeading: false,
      titleSpacing: 0.0,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(Icons.close),
              color: Colors.white,
              iconSize: Dimensions.buttonAppBarSize,
              onPressed: onDismissMessageOptions,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.info_outline),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Chat Details',
          color: Colors.white,
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/home/chat/settings',
              arguments: ChatSettingsArguments(
                roomId: selectedRoom.id,
                title: selectedRoom.name,
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.archive),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Archive Room',
          color: Colors.white,
          onPressed: () async {
            await props.onArchiveRoom(room: this.selectedRoom);
            this.setState(() {
              selectedRoom = null;
            });
          },
        ),
        Visibility(
          visible: true,
          child: IconButton(
            icon: Icon(Icons.exit_to_app),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Leave Chat',
            color: Colors.white,
            onPressed: () async {
              await props.onLeaveChat(room: this.selectedRoom);
              this.setState(() {
                selectedRoom = null;
              });
            },
          ),
        ),
        Visibility(
          visible: this.selectedRoom.direct,
          child: IconButton(
            icon: Icon(Icons.delete_outline),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: 'Delete Chat',
            color: Colors.white,
            onPressed: () async {
              await props.onDeleteChat(room: this.selectedRoom);
              this.setState(() {
                selectedRoom = null;
              });
            },
          ),
        ),
        IconButton(
          icon: Icon(Icons.select_all),
          iconSize: Dimensions.buttonAppBarSize,
          tooltip: 'Select All',
          color: Colors.white,
          onPressed: () {},
        ),
      ],
    );
  }

  @protected
  Widget buildAppBar({BuildContext context, _Props props}) => AppBar(
        automaticallyImplyLeading: false,
        brightness: Brightness.dark,
        titleSpacing: 16.00,
        title: Row(
          children: <Widget>[
            AvatarAppBar(
              user: props.currentUser,
              offline: props.offline,
              syncing: (props.syncing && props.offline) || props.loadingRooms,
              tooltip: 'Profile and Settings',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
            ),
            Text(
              Values.appName,
              style: Theme.of(context).textTheme.headline6.copyWith(
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            color: Colors.white,
            icon: Icon(Icons.search),
            tooltip: 'Search Chats',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          RoundedPopupMenu<Options>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (Options result) {
              switch (result) {
                case Options.newGroup:
                  Navigator.pushNamed(context, '/home/groups/create');
                  break;
                case Options.markAllRead:
                  props.onMarkAllRead();
                  break;
                case Options.settings:
                  Navigator.pushNamed(context, '/settings');
                  break;
                case Options.help:
                  props.onSelectHelp();
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
                enabled: false,
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
      );

  @protected
  Widget buildChatList(List<Room> rooms, BuildContext context, _Props props) {
    if (rooms.isEmpty) {
      return Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            constraints: BoxConstraints(
              minWidth: Dimensions.mediaSizeMin,
              maxWidth: Dimensions.mediaSizeMax,
              maxHeight: Dimensions.mediaSizeMin,
            ),
            child: SvgPicture.asset(
              Assets.heroChatNotFound,
              semanticsLabel: Strings.semanticsLabelHomeEmpty,
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                Strings.labelNoMessages,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ],
      ));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];
        final messages = room.messages ?? const [];
        final messagesLatest = latestMessages(room.messages);
        final messagePreview = formatPreview(
          room: room,
          prefetched: messagesLatest,
        );
        final roomSettings = props.chatSettings[room.id] ?? null;

        bool messagesNew = false;
        var backgroundColor;
        var textStyle = TextStyle();
        var primaryColor = Colors.grey[500];

        // Check settings for custom color, then check temp cache,
        // or generate new temp color
        if (roomSettings != null) {
          primaryColor = Color(roomSettings.primaryColor);
        } else if (roomColorDefaults.containsKey(room.id)) {
          primaryColor = roomColorDefaults[room.id];
        } else {
          debugPrint('[ListView.builder] generating new color');
          primaryColor = Colours.hashedColor(room.id);
          roomColorDefaults.putIfAbsent(
            room.id,
            () => primaryColor,
          );
        }

        if (selectedRoom != null) {
          if (selectedRoom.id != room.id) {
            backgroundColor = Theme.of(context).scaffoldBackgroundColor;
          } else {
            backgroundColor = Theme.of(context).primaryColor.withAlpha(128);
          }
        }

        // show draft inidicator if it's an empty room
        if (messages == null || messages.length < 1) {
          textStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        // it has undecrypted message contained within
        if (messages != null &&
            messages.length > 0 &&
            messages[0].type == EventTypes.encrypted &&
            messages[0].body.isEmpty) {
          textStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        if (messages != null && messages.isNotEmpty) {
          final messageRecent = messagesLatest[0];

          if (room.lastRead < messageRecent.timestamp) {
            messagesNew = true;
            textStyle = textStyle.copyWith(
              color: Theme.of(context).textTheme.bodyText1.color,
              fontWeight: FontWeight.w500,
            );
          }
        }

        // GestureDetector w/ animation
        return InkWell(
          onTap: () {
            if (this.selectedRoom != null) {
              this.onDismissMessageOptions();
            } else {
              Navigator.pushNamed(
                context,
                '/home/chat',
                arguments: ChatViewArguements(
                  roomId: room.id,
                  title: room.name,
                ),
              );
            }
          },
          onLongPress: () => onToggleRoomOptions(room: room),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor, // if selected, color seperately
            ),
            padding: EdgeInsets.symmetric(
              vertical: Theme.of(context).textTheme.subtitle1.fontSize,
            ).add(Dimensions.appPaddingHorizontal),
            child: Flex(
              direction: Axis.horizontal,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      AvatarCircle(
                        uri: room.avatarUri,
                        size: Dimensions.avatarSizeMin,
                        alt: formatRoomInitials(room: room),
                        background: primaryColor,
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled &&
                            room.encryptionEnabled,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                width: Dimensions.badgeAvatarSize,
                                height: Dimensions.badgeAvatarSize,
                                color: Colors.green,
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: Dimensions.iconSizeMini,
                                ),
                              )),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled && room.invite,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Colors.grey,
                              child: Icon(
                                Icons.mail_outline,
                                color: Colors.white,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: messagesNew,
                        child: Positioned(
                          top: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSizeSmall,
                              height: Dimensions.badgeAvatarSizeSmall,
                              color: Theme.of(context).accentColor,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled &&
                            room.type == 'group' &&
                            !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.group,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSizeSmall,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: props.roomTypeBadgesEnabled &&
                            room.type == 'public' &&
                            !room.invite,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.public,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.badgeAvatarSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          Expanded(
                            child: Text(
                              room.name,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                          Text(
                            formatTimestamp(lastUpdateMillis: room.lastUpdate),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w100),
                          ),
                        ],
                      ),
                      Container(
                        child: Text(
                          messagePreview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.caption.merge(
                                textStyle,
                              ),
                        ),
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
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          var currentAppBar = buildAppBar(
            props: props,
            context: context,
          );

          if (this.selectedRoom != null) {
            currentAppBar = buildAppBarRoomOptions(
              props: props,
              context: context,
            );
          }

          return Scaffold(
            appBar: currentAppBar,
            floatingActionButton: ActionRing(fabKey: fabKey),
            body: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () {
                        return props.onFetchSyncForced();
                      },
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: this.onDismissMessageOptions,
                            child: buildChatList(
                              props.rooms,
                              context,
                              props,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final List<Room> rooms;
  final bool offline;
  final bool syncing;
  final bool loadingRooms;
  final bool roomTypeBadgesEnabled;
  final User currentUser;
  final Map<String, ChatSetting> chatSettings;

  final Function onLeaveChat;
  final Function onDeleteChat;
  final Function onSelectHelp;
  final Function onArchiveRoom;
  final Function onMarkAllRead;
  final Function onFetchSyncForced;

  _Props({
    @required this.rooms,
    @required this.offline,
    @required this.syncing,
    @required this.currentUser,
    @required this.loadingRooms,
    @required this.chatSettings,
    @required this.roomTypeBadgesEnabled,
    @required this.onLeaveChat,
    @required this.onDeleteChat,
    @required this.onSelectHelp,
    @required this.onArchiveRoom,
    @required this.onMarkAllRead,
    @required this.onFetchSyncForced,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        rooms: availableRooms(
          sortedPrioritizedRooms(store.state.roomStore.rooms),
          hidden: store.state.roomStore.roomsHidden,
        ),
        offline: store.state.syncStore.offline,
        syncing: () {
          final syncing = store.state.syncStore.syncing;
          final offline = store.state.syncStore.offline;
          final loadingRooms = store.state.roomStore.loading;

          final lastAttempt = DateTime.fromMillisecondsSinceEpoch(
              store.state.syncStore.lastAttempt);

          // See if the last attempted sync is older than 60 seconds
          final isLastAttemptOld = DateTime.now()
              .difference(lastAttempt)
              .compareTo(Duration(seconds: 60));

          if (syncing && offline) {
            return true;
          }
          if (loadingRooms) {
            return true;
          }

          if (syncing && 0 < isLastAttemptOld) {
            return true;
          }

          return false;
        }(),
        currentUser: store.state.authStore.user,
        loadingRooms: store.state.roomStore.loading,
        roomTypeBadgesEnabled:
            store.state.settingsStore.roomTypeBadgesEnabled ?? true,
        chatSettings: store.state.settingsStore.customChatSettings ?? Map(),
        onMarkAllRead: () {
          store.dispatch(markRoomsReadAll());
        },
        onArchiveRoom: ({Room room}) async {
          store.dispatch(archiveRoom(room: room));
        },
        onFetchSyncForced: () async {
          await store.dispatch(
            fetchSync(since: store.state.syncStore.lastSince),
          );
          return Future(() => true);
        },
        onLeaveChat: ({Room room}) {
          return store.dispatch(
            leaveRoom(room: room),
          );
        },
        onDeleteChat: ({Room room}) {
          return store.dispatch(
            removeRoom(room: room),
          );
        },
        onSelectHelp: () async {
          try {
            if (await canLaunch(Values.openHelpUrl)) {
              await launch(Values.openHelpUrl);
            } else {
              throw 'Could not launch ${Values.openHelpUrl}';
            }
          } catch (error) {}
        },
      );

  @override
  List<Object> get props => [
        rooms,
        offline,
        currentUser,
        loadingRooms,
        chatSettings,
      ];
}
