import 'package:Tether/global/dimensions.dart';
import 'package:Tether/global/strings.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/room/selectors.dart';
import 'package:Tether/store/settings/chat-settings/model.dart';
import 'package:Tether/store/user/model.dart';
import 'package:Tether/store/user/selectors.dart';
import 'package:Tether/global/assets.dart';
import 'package:Tether/views/home/chat/details-chat.dart';
import 'package:Tether/views/widgets/image-matrix.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:redux/redux.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Store
import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/room/model.dart';
import 'package:Tether/store/rooms/selectors.dart';
import 'package:Tether/global/formatters.dart';

// View And Styling
import 'package:Tether/views/widgets/menu.dart';
import 'package:Tether/views/home/chat/index.dart';
import 'package:Tether/global/colors.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, help }

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  HomeViewState createState() => HomeViewState();
}

class HomeViewState extends State<Home> {
  HomeViewState({Key key}) : super();

  // TODO: allow multi-select
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
  Widget buildRoomOptionsBar({BuildContext context, _Props props}) {
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
          onPressed: () {},
        ),
        Visibility(
          visible: true,
          child: true
              ? IconButton(
                  icon: Icon(Icons.delete_outline),
                  iconSize: Dimensions.buttonAppBarSize,
                  tooltip: 'Leave Chat',
                  color: Colors.white,
                  onPressed: () async {
                    await props.onLeaveChat(room: this.selectedRoom);
                    this.setState(() {
                      selectedRoom = null;
                    });
                  },
                )
              : IconButton(
                  icon: Icon(Icons.do_not_disturb_alt),
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
      titleSpacing: 18.00,
      title: Row(children: <Widget>[
        Container(
          margin: EdgeInsets.only(right: 8),
          child: IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.grey,
              child: props.currentUser.avatarUri != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(
                        Dimensions.thumbnailSizeMax,
                      ),
                      child: MatrixImage(
                        mxcUri: props.currentUser.avatarUri,
                        thumbnail: true,
                      ),
                    )
                  : Text(
                      displayInitials(props.currentUser),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            tooltip: 'Profile and Settings',
          ),
        ),
        Text(
          StringStore.app_name,
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
        final roomSettings = props.chatSettings[room.id] ?? null;

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

        if (room.messages == null || room.messages.length < 1) {
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
                  child: CircleAvatar(
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
        converter: (Store<AppState> store) => _Props.mapStoreToProps(store),
        builder: (context, props) {
          var currentAppBar = buildAppBar(
            props: props,
            context: context,
          );

          if (this.selectedRoom != null) {
            currentAppBar = buildRoomOptionsBar(
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
                          Positioned(
                            child: Visibility(
                              visible: props.loadingRooms,
                              child: Container(
                                  child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  RefreshProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor:
                                        new AlwaysStoppedAnimation<Color>(
                                      PRIMARY_COLOR,
                                    ),
                                    value: null,
                                  ),
                                ],
                              )),
                            ),
                          ),
                          GestureDetector(
                            onTap: this.onDismissMessageOptions,
                            child: buildChatList(
                              sortedPrioritizedRooms(props.rooms),
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
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                  ),
                  tooltip: 'Direct Message',
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
                  onPressed: () => onNavigateToGroupSearch(context),
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final Map rooms;
  final bool loadingRooms;
  final User currentUser;
  final Map<String, ChatSetting> chatSettings;

  final Function onFetchSyncForced;
  final Function onLeaveChat;
  final Function onDeleteChat;

  _Props({
    @required this.rooms,
    @required this.currentUser,
    @required this.loadingRooms,
    @required this.chatSettings,
    @required this.onFetchSyncForced,
    @required this.onLeaveChat,
    @required this.onDeleteChat,
  });

  static _Props mapStoreToProps(Store<AppState> store) => _Props(
        rooms: store.state.roomStore.rooms,
        loadingRooms: store.state.roomStore.loading,
        currentUser: store.state.userStore.user,
        chatSettings: store.state.settingsStore.customChatSettings ?? Map(),
        onFetchSyncForced: () {
          store.dispatch(
            fetchSync(since: store.state.roomStore.lastSince),
          );
        },
        onLeaveChat: ({Room room}) {
          return store.dispatch(
            removeRoom(room: room),
          );
        },
        onDeleteChat: ({Room room}) {
          return store.dispatch(
            deleteRoom(room: room),
          );
        },
      );

  @override
  List<Object> get props => [
        rooms,
        currentUser,
        loadingRooms,
        chatSettings,
      ];
}
