import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/events/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/widgets/avatars/avatar-app-bar.dart';
import 'package:syphon/views/widgets/image-matrix.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Store
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/global/formatters.dart';

// View And Styling
import 'package:syphon/views/widgets/menu-rounded.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:url_launcher/url_launcher.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, licenses, help }

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<Home> {
  HomeViewState({Key key}) : super();

  Room selectedRoom;

  @protected
  onNavigateToGroupSearch(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/home/groups/search');
  }

  @protected
  onNavigateToDraft(context) {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/home/user/search');
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
      brightness: Brightness.dark, // TOOD: this should inherit from theme
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
            icon: Icon(Icons.do_not_disturb_alt),
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
  Widget buildAppBar({BuildContext context, _Props props}) {
    return AppBar(
      automaticallyImplyLeading: false,
      brightness: Brightness.dark,
      titleSpacing: 16.00,
      title: Row(children: <Widget>[
        AvatarAppBar(
          user: props.currentUser,
          offline: props.offline,
          // show syncing if offline and refresh or initial sync
          syncing: (props.syncing && props.offline) || props.loadingRooms,
          tooltip: 'Profile and Settings',
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        Text(
          Values.appName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w400,
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
              case Options.newGroup:
                // TODO: allow users to create and edit groups
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
              enabled: false,
              child: Text('New Group'),
            ),
            const PopupMenuItem<Options>(
              value: Options.markAllRead,
              enabled: false,
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
  }

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
          Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                'there\'s no messages yet',
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
        final messages = room.messages;
        final roomSettings = props.chatSettings[room.id] ?? null;
        final roomPreview = formatPreview(room: room);

        var primaryColor =
            room.avatarUri != null ? Colors.transparent : Colors.grey;
        var backgroundColor;
        var fontStyle;

        if (roomSettings != null) {
          primaryColor = Color(roomSettings.primaryColor);
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
          fontStyle = FontStyle.italic;
        }

        // it has undecrypted message contained within
        if (messages != null &&
            messages.length > 0 &&
            messages[0].type == EventTypes.encrypted &&
            messages[0].body.isEmpty) {
          fontStyle = FontStyle.italic;
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
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryColor,
                        child: room.avatarUri != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.thumbnailSizeMax,
                                ),
                                child: MatrixImage(
                                  width: Dimensions.avatarSize,
                                  height: Dimensions.avatarSize,
                                  mxcUri: room.avatarUri,
                                  fallbackColor: primaryColor,
                                  fallback: Text(
                                    formatRoomInitials(room: room),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                formatRoomInitials(room: room),
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                      Visibility(
                        visible: room.encryptionEnabled,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimensions.thumbnailSizeMax,
                              ),
                              child: Container(
                                height: 16,
                                width: 16,
                                color: Colors.green,
                                child: Icon(
                                  Icons.lock,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              )),
                        ),
                      ),
                      Visibility(
                        visible: room.invite,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimensions.thumbnailSizeMax,
                              ),
                              child: Container(
                                height: 16,
                                width: 16,
                                color: Colors.grey,
                                child: Icon(
                                  Icons.mail_outline,
                                  color: Colors.white,
                                  size: 10,
                                ),
                              )),
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
                          Text(
                            formatRoomName(room: room),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyText1,
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
                        roomPreview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption.merge(
                              TextStyle(fontStyle: fontStyle),
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
                          // TODO: decide if /sync indicator
                          // should just be on current user avatar
                          // Positioned(
                          //   child: Visibility(
                          //     visible: props.loadingRooms,
                          //     child: Container(
                          //         child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       children: <Widget>[
                          //         RefreshProgressIndicator(
                          //           strokeWidth: Dimensions.defaultStrokeWidth,
                          //           valueColor:
                          //               new AlwaysStoppedAnimation<Color>(
                          //             PRIMARY_COLOR,
                          //           ),
                          //           value: null,
                          //         ),
                          //       ],
                          //     )),
                          //   ),
                          // ),
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
              fabOpenIcon: Icon(
                Icons.bubble_chart,
                size: 32.0,
                color: Colors.white,
              ),
              fabCloseIcon: Icon(
                Icons.close,
                color: Colors.white,
              ),
              fabColor: Theme.of(context).accentColor,
              ringDiameter: MediaQuery.of(context).size.width * 0.9,
              ringColor: Theme.of(context).accentColor.withAlpha(144),
              animationDuration: Duration(milliseconds: 275),
              onDisplayChange: (opened) {},
              children: [
                FloatingActionButton(
                  heroTag: 'fab2',
                  child: Icon(
                    Icons.group_add,
                    // Icons.widgets,
                    color: Colors.white,
                  ),
                  tooltip: 'Create Chat Or Group',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                  },
                ),
                FloatingActionButton(
                  heroTag: 'fab3',
                  tooltip: 'Direct Message',
                  onPressed: () => onNavigateToDraft(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.person_add,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'fab1',
                  child: Icon(
                    Icons.search,
                    color: Colors.white,
                  ),
                  tooltip: 'Search Groups',
                  onPressed: () => onNavigateToGroupSearch(context),
                ),
              ],
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
  final User currentUser;
  final Map<String, ChatSetting> chatSettings;

  final Function onLeaveChat;
  final Function onDeleteChat;
  final Function onFetchSyncForced;
  final Function onSelectHelp;
  final Function onArchiveRoom;

  _Props({
    @required this.rooms,
    @required this.offline,
    @required this.syncing,
    @required this.currentUser,
    @required this.loadingRooms,
    @required this.chatSettings,
    @required this.onLeaveChat,
    @required this.onDeleteChat,
    @required this.onFetchSyncForced,
    @required this.onSelectHelp,
    @required this.onArchiveRoom,
  });

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        rooms: availableRooms(
          sortedPrioritizedRooms(store.state.roomStore.rooms),
          hidden: store.state.roomStore.roomsHidden,
        ),
        loadingRooms: store.state.roomStore.loading,
        offline: store.state.syncStore.offline,
        syncing: store.state.syncStore.syncing,
        currentUser: store.state.authStore.user,
        chatSettings: store.state.settingsStore.customChatSettings ?? Map(),
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
