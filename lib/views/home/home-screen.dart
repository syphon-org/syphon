import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/assets.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/formatters.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/global/weburl.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/rooms/selectors.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/chat-settings/model.dart';
import 'package:syphon/store/settings/chat-settings/selectors.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:syphon/store/sync/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/chat-detail-screen.dart';
import 'package:syphon/views/home/chat/chat-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/appbars/appbar-avatar.dart';
import 'package:syphon/views/widgets/appbars/appbar-search.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/fabs/fab-bar-expanding.dart';
import 'package:syphon/views/widgets/containers/fabs/fab-circle-expanding.dart';
import 'package:syphon/views/widgets/containers/fabs/fab-ring.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/loader/index.dart';

enum Options { newGroup, markAllRead, inviteFriends, settings, licenses, help }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<HomeScreen> {
  HomeState() : super();

  final searchInputFocusNode = FocusNode();

  final fabKeyBar = GlobalKey<FabBarContainerState>();
  final fabKeyRing = GlobalKey<FabCircularMenuState>();
  final fabKeyCircle = GlobalKey<FabBarContainerState>();

  bool searching = false;
  String searchText = '';
  Map<String, Room> selectedChats = {};
  Map<String, Color> chatColorCache = {};

  @protected
  onToggleRoomOptions({required Room room}) {
    if (searching) {
      onToggleSearch();
    }
    if (!selectedChats.containsKey(room.id)) {
      setState(() {
        selectedChats.addAll({room.id: room});
      });
    } else {
      setState(() {
        selectedChats.remove(room.id);
      });
    }
  }

  @protected
  onDismissMessageOptions() {
    setState(() {
      selectedChats = {};
    });
  }

  onArchiveChats(_Props props) async {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.buttonArchiveChat.capitalize(),
        content: Strings.confirmArchiveRooms(rooms: selectedChats.values),
        confirmStyle: TextStyle(color: Colors.red),
        confirmText: Strings.buttonConfirmFormal.capitalize(),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          await Future.forEach(selectedChats.values, (room) async {
            await props.onArchiveChat(room: room);
          });
          setState(() {
            selectedChats = {};
          });
        },
      ),
    );
  }

  onLeaveChats(_Props props) async {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.buttonLeaveChat.capitalize(),
        content: Strings.confirmLeaveRooms(rooms: selectedChats.values),
        confirmStyle: TextStyle(color: Colors.red),
        confirmText: Strings.buttonConfirmFormal.capitalize(),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();
          final _selectedChats = Map<String, Room>.from(selectedChats);
          await Future.forEach<Room>(_selectedChats.values, (Room room) async {
            await props.onLeaveChat(room: room);
            onToggleRoomOptions(room: room);
          });
          setState(() {
            selectedChats = {};
          });
        },
      ),
    );
  }

  onDeleteChats(_Props props) async {
    showDialog(
      context: context,
      builder: (dialogContext) => DialogConfirm(
        title: Strings.buttonDeleteChat.capitalize(),
        content: Strings.confirmDeleteRooms(rooms: selectedChats.values),
        confirmStyle: TextStyle(color: Colors.red),
        confirmText: Strings.buttonConfirmFormal.capitalize(),
        onDismiss: () => Navigator.pop(dialogContext),
        onConfirm: () async {
          Navigator.of(dialogContext).pop();

          final _selectedChats = Map<String, Room>.from(selectedChats);
          await Future.forEach(_selectedChats.values, (room) async {
            await props.onDeleteChat(room: room);
          });
          setState(() {
            selectedChats = {};
          });
        },
      ),
    );
  }

  onToggleSearch() {
    setState(() {
      searching = !searching;
      searchText = '';
    });
  }

  onSearch(_Props props, String text) {
    final store = StoreProvider.of<AppState>(context);
    setState(() {
      searchText = text;
    });

    if (text.isEmpty) {
      return store.dispatch(clearSearchResults());
    }

    store.dispatch(searchMessages(text));
  }

  onSelectChat(Room room, String chatName) {
    final store = StoreProvider.of<AppState>(context);

    if (selectedChats.isNotEmpty) {
      return onToggleRoomOptions(room: room);
    }

    Navigator.pushNamed(
      context,
      Routes.chat,
      arguments: ChatScreenArguments(roomId: room.id, title: chatName),
    );

    Timer(Duration(milliseconds: 500), () {
      setState(() {
        searching = false;
        selectedChats = {};
      });
      store.dispatch(clearSearchResults());
    });
  }

  onSelectAll(_Props props) {
    if (selectedChats.values.toSet().containsAll(props.rooms)) {
      setState(() {
        selectedChats = {};
      });
    } else {
      setState(() {
        selectedChats.addAll(Map.fromEntries(props.rooms.map((e) => MapEntry(e.id, e))));
      });
    }
  }

  bool isAllDirect(Map<String, Room> selectedChats) {
    return selectedChats.values.every((chat) => chat.direct);
  }

  @protected
  Widget buildAppBarRoomOptions({required BuildContext context, required _Props props}) => AppBar(
        backgroundColor: Color(Colours.greyDefault),
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
                tooltip: Strings.labelClose.capitalize(),
                onPressed: () => onDismissMessageOptions(),
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Visibility(
            visible: selectedChats.length == 1,
            child: IconButton(
              icon: Icon(Icons.info_outline),
              iconSize: Dimensions.buttonAppBarSize,
              tooltip: Strings.buttonRoomDetails.capitalize(),
              color: Colors.white,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.chatDetails,
                  arguments: ChatDetailsArguments(
                    roomId: selectedChats.values.first.id,
                    title: selectedChats.values.first.name,
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.archive_outlined),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: Strings.buttonArchiveChat.capitalize(),
            color: Colors.white,
            onPressed: () => onArchiveChats(props),
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: Strings.buttonLeaveChat.capitalize(),
            color: Colors.white,
            onPressed: () => onLeaveChats(props),
          ),
          Visibility(
            visible: isAllDirect(selectedChats),
            child: IconButton(
              icon: Icon(Icons.delete_outline),
              iconSize: Dimensions.buttonAppBarSize,
              tooltip: Strings.buttonDeleteChat.capitalize(),
              color: Colors.white,
              onPressed: () => onDeleteChats(props),
            ),
          ),
          IconButton(
            icon: Icon(Icons.select_all),
            iconSize: Dimensions.buttonAppBarSize,
            tooltip: Strings.buttonSelectAll.capitalize(),
            color: Colors.white,
            onPressed: () => onSelectAll(props),
          ),
        ],
      );

  @protected
  Widget buildAppBar({required BuildContext context, required _Props props}) {
    final assetColor = computeContrastColorText(
      Theme.of(context).appBarTheme.backgroundColor,
    );

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 16.00,
      title: Row(
        children: <Widget>[
          AppBarAvatar(
            themeType: props.themeType,
            user: props.currentUser,
            offline: props.offline,
            syncing: props.syncing,
            unauthed: props.unauthed,
            tooltip: Strings.tooltipProfileAndSettings,
            onPressed: () {
              Navigator.pushNamed(context, Routes.settingsProfile);
            },
          ),
          Text(
            Values.appName,
            style: Theme.of(context).textTheme.headline6!.copyWith(
                  fontWeight: FontWeight.w400,
                  color: assetColor,
                ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          color: assetColor,
          icon: Icon(Icons.search),
          tooltip: Strings.tooltipSearchChats,
          onPressed: () => onToggleSearch(),
        ),
        RoundedPopupMenu<Options>(
          icon: Icon(
            Icons.more_vert,
            color: assetColor,
          ),
          onSelected: (Options result) {
            switch (result) {
              case Options.newGroup:
                Navigator.pushNamed(context, Routes.groupCreate);
                break;
              case Options.markAllRead:
                props.onMarkAllRead();
                break;
              case Options.settings:
                Navigator.pushNamed(context, Routes.settings);
                break;
              case Options.help:
                props.onSelectHelp();
                break;
              default:
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<Options>>[
            PopupMenuItem<Options>(
              value: Options.newGroup,
              child: Text(Strings.buttonTextCreateGroup),
            ),
            PopupMenuItem<Options>(
              value: Options.markAllRead,
              child: Text(Strings.buttonTextMarkAllRead),
            ),
            PopupMenuItem<Options>(
              value: Options.inviteFriends,
              enabled: false,
              child: Text(Strings.buttonTextInvite),
            ),
            PopupMenuItem<Options>(
              value: Options.settings,
              child: Text(Strings.buttonTextSettings),
            ),
            PopupMenuItem<Options>(
              value: Options.help,
              child: Text(Strings.buttonTextSupport),
            ),
          ],
        )
      ],
    );
  }

  @protected
  Widget buildChatList(BuildContext context, _Props props) {
    final store = StoreProvider.of<AppState>(context);
    final rooms = props.rooms;
    final label = props.syncing ? Strings.labelSyncing : Strings.labelMessagesEmpty;
    final noSearchResults = searching && props.searchMessages.isEmpty && searchText.isNotEmpty;

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
              semanticsLabel: Strings.semanticsHomeDefault,
            ),
          ),
          GestureDetector(
            child: Container(
              margin: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.only(top: 16),
              child: Text(
                label,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ),
        ],
      ));
    }

    return ListView.builder(
      scrollDirection: Axis.vertical,
      itemCount: noSearchResults ? 0 : rooms.length,
      itemBuilder: (BuildContext context, int index) {
        final room = rooms[index];
        final messages = props.messages[room.id] ?? const [];
        final decrypted = props.decrypted[room.id] ?? const [];

        final messageLatest = latestMessage(messages, room: room, decrypted: decrypted);
        final preview = formatPreview(room: room, message: messageLatest);
        final chatName = room.name ?? '';
        final newMessage = messageLatest != null &&
            room.lastRead < messageLatest.timestamp &&
            messageLatest.sender != props.currentUser.userId;

        var backgroundColor;
        var textStyle = TextStyle();
        final chatColor = selectChatColor(store, room.id);

        // highlight selected rooms if necessary
        if (selectedChats.isNotEmpty) {
          if (!selectedChats.containsKey(room.id)) {
            backgroundColor = Theme.of(context).scaffoldBackgroundColor;
          } else {
            backgroundColor = Theme.of(context).primaryColor.withAlpha(128);
          }
        }

        // show draft inidicator if it's an empty room
        if (room.drafting || messages.isEmpty) {
          textStyle = TextStyle(fontStyle: FontStyle.italic);
        }

        if (messages.isNotEmpty && messageLatest != null) {
          // it has undecrypted message contained within
          if (messageLatest.type == EventTypes.encrypted && messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
          }

          if (messageLatest.body == null || messageLatest.body!.isEmpty) {
            textStyle = TextStyle(fontStyle: FontStyle.italic);
          }

          // display message as being 'unread'
          if (newMessage) {
            textStyle = textStyle.copyWith(
              color: Theme.of(context).textTheme.bodyText1!.color,
              fontWeight: FontWeight.w500,
            );
          }
        }

        // GestureDetector w/ animation
        return InkWell(
          onTap: () => onSelectChat(room, chatName),
          onLongPress: () => onToggleRoomOptions(room: room),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor, // if selected, color seperately
            ),
            padding: EdgeInsets.symmetric(
              vertical: Theme.of(context).textTheme.subtitle1!.fontSize!,
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
                      Avatar(
                        uri: room.avatarUri,
                        size: Dimensions.avatarSizeMin,
                        alt: formatRoomInitials(room: room),
                        background: chatColor,
                      ),
                      Visibility(
                        visible: !room.encryptionEnabled,
                        child: Positioned(
                          bottom: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              Dimensions.badgeAvatarSize,
                            ),
                            child: Container(
                              width: Dimensions.badgeAvatarSize,
                              height: Dimensions.badgeAvatarSize,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.lock_open,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
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
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(
                                Icons.mail_outline,
                                color: Theme.of(context).iconTheme.color,
                                size: Dimensions.iconSizeMini,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: newMessage,
                        child: Positioned(
                          top: 0,
                          right: 0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: Dimensions.badgeAvatarSizeSmall,
                              height: Dimensions.badgeAvatarSizeSmall,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible:
                            props.roomTypeBadgesEnabled && room.type == 'group' && !room.invite,
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
                        visible:
                            props.roomTypeBadgesEnabled && room.type == 'public' && !room.invite,
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
                              chatName,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                          Text(
                            formatTimestamp(lastUpdateMillis: room.lastUpdate),
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w100),
                          ),
                        ],
                      ),
                      Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.caption!.merge(
                              textStyle,
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

  selectActionAlignment(_Props props) {
    if (props.fabLocation == MainFabLocation.Left) {
      return Alignment.bottomLeft;
    }

    return Alignment.bottomRight;
  }

  buildActionFab(_Props props) {
    final fabType = props.fabType;

    if (fabType == MainFabType.Bar) {
      return FabBarExpanding(
        alignment: selectActionAlignment(props),
      );
    }

    return FabRing(
      fabKey: fabKeyRing,
      alignment: selectActionAlignment(props),
    );
  }

  selectActionLocation(_Props props) {
    if (props.fabLocation == MainFabLocation.Left) {
      return FloatingActionButtonLocation.startFloat;
    }

    return FloatingActionButtonLocation.endFloat;
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

          if (selectedChats.isNotEmpty) {
            currentAppBar = buildAppBarRoomOptions(
              props: props,
              context: context,
            );
          }

          if (searching) {
            currentAppBar = AppBarSearch(
              title: Strings.titleSearchUnencrypted,
              label: Strings.labelSearchUnencrypted,
              tooltip: Strings.tooltipSearchUnencrypted,
              forceFocus: true,
              navigate: false,
              startFocused: true,
              focusNode: searchInputFocusNode,
              onBack: () => onToggleSearch(),
              onToggleSearch: () => onToggleSearch(),
              onSearch: (String text) => onSearch(props, text),
            );
          }

          return Scaffold(
            appBar: currentAppBar as PreferredSizeWidget?,
            floatingActionButton: buildActionFab(props),
            floatingActionButtonLocation: selectActionLocation(props),
            body: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => props.onFetchSyncForced(),
                      child: Stack(
                        children: [
                          Positioned(
                            child: Loader(
                              loading: props.searching,
                            ),
                          ),
                          GestureDetector(
                            onTap: onDismissMessageOptions,
                            child: buildChatList(
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
  final bool? offline;
  final bool syncing;
  final bool unauthed;
  final bool roomTypeBadgesEnabled;
  final User currentUser;
  final bool searching;

  final ThemeType themeType;
  final MainFabType fabType;
  final MainFabLocation fabLocation;
  final List<Message> searchMessages;
  final Map<String, ChatSetting> chatSettings;
  final Map<String, List<Message>> messages;
  final Map<String, List<Message>> decrypted;

  final Function onLeaveChat;
  final Function onDeleteChat;
  final Function onArchiveChat;
  final Function onSelectHelp;
  final Function onMarkAllRead;
  final Function onFetchSyncForced;

  const _Props({
    required this.rooms,
    required this.themeType,
    required this.offline,
    required this.syncing,
    required this.searching,
    required this.unauthed,
    required this.messages,
    required this.decrypted,
    required this.currentUser,
    required this.chatSettings,
    required this.searchMessages,
    required this.fabType,
    required this.fabLocation,
    required this.roomTypeBadgesEnabled,
    required this.onLeaveChat,
    required this.onDeleteChat,
    required this.onSelectHelp,
    required this.onArchiveChat,
    required this.onMarkAllRead,
    required this.onFetchSyncForced,
  });

  @override
  List<Object?> get props => [
        rooms,
        messages,
        themeType,
        syncing,
        searching,
        offline,
        unauthed,
        currentUser,
        chatSettings,
        roomTypeBadgesEnabled,
        fabType,
        fabLocation,
      ];

  static _Props mapStateToProps(Store<AppState> store) => _Props(
        themeType: store.state.settingsStore.themeSettings.themeType,
        rooms: availableRooms(sortPrioritizedRooms(filterSearches(
          filterBlockedRooms(
            store.state.roomStore.roomList,
            store.state.userStore.blocked,
          ),
          store.state.searchStore.searchMessages,
        ))),
        messages: store.state.eventStore.messages,
        decrypted: store.state.eventStore.messagesDecrypted,
        unauthed: store.state.syncStore.unauthed,
        offline: store.state.syncStore.offline,
        fabType: store.state.settingsStore.themeSettings.mainFabType,
        fabLocation: store.state.settingsStore.themeSettings.mainFabLocation,
        syncing: selectSyncingStatus(store.state),
        searching: store.state.searchStore.loading,
        searchMessages: store.state.searchStore.searchMessages,
        currentUser: store.state.authStore.user,
        roomTypeBadgesEnabled: store.state.settingsStore.roomTypeBadgesEnabled,
        chatSettings: store.state.settingsStore.chatSettings,
        onMarkAllRead: () {
          store.dispatch(markRoomsReadAll());
        },
        onLeaveChat: ({Room? room}) {
          return store.dispatch(leaveRoom(room: room));
        },
        onDeleteChat: ({Room? room}) {
          return store.dispatch(removeRoom(room: room));
        },
        onArchiveChat: ({Room? room}) async {
          store.dispatch(archiveRoom(room: room));
        },
        onFetchSyncForced: () async {
          await store.dispatch(
            fetchSync(since: store.state.syncStore.lastSince),
          );
          return Future(() => true);
        },
        onSelectHelp: () async {
          await launchUrl(Values.openHelpUrl);
        },
      );
}
