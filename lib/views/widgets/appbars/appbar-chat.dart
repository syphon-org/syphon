import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/chat-detail-screen.dart';
import 'package:syphon/views/home/groups/invite-users-screen.dart';
import 'package:syphon/views/navigation.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';
import 'package:syphon/views/widgets/dialogs/dialog-rounded.dart';
import 'package:syphon/views/widgets/lifecycle.dart';

enum ChatOptions {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications,
  blockUser,
}

class AppBarChat extends StatefulWidget implements PreferredSizeWidget {
  final bool loading;
  final bool forceFocus;
  final bool badgesEnabled;
  final Room room;
  final Color? color;
  final String title;
  final String label;
  final String tooltip;
  final double? elevation;
  final Brightness brightness;
  final FocusNode? focusNode;

  final Function? onBack;
  final Function? onDebug;
  final Function? onSearch;
  final Function? onToggleSearch;

  const AppBarChat({
    Key? key,
    this.title = 'title:',
    this.label = 'label:',
    this.tooltip = 'tooltip:',
    this.room = const Room(id: 'temp'),
    this.color,
    this.brightness = Brightness.dark,
    this.elevation,
    this.focusNode,
    this.onBack,
    this.onDebug,
    this.onSearch,
    this.onToggleSearch,
    this.badgesEnabled = true,
    this.forceFocus = false,
    this.loading = false,
  }) : super(key: key);

  @override
  AppBarChatState createState() => AppBarChatState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class AppBarChatState extends State<AppBarChat> with Lifecycle<AppBarChat> {
  final focusNode = FocusNode();

  bool searching = false;
  Timer? searchTimeout;

  @override
  void onMounted() {
    if (widget.forceFocus) {
      // TODO: implement chat searching
    }
  }

  onBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.pop(context);
    }
  }

  onBlockUser({required BuildContext context, required _Props props}) {
    final user = props.roomUsers.firstWhere(
      (user) => user!.userId != props.currentUser.userId,
    );

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DialogConfirm(
        title: 'Block User',
        content:
            'If you block ${user!.displayName}, you will not be able to see their messages and you will immediately leave this chat.',
        onConfirm: () async {
          await props.onBlockUser(user.userId);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  onToggleSearch({BuildContext? context}) {
    setState(() {
      searching = !searching;
    });
    if (searching) {
      Timer(
        Duration(milliseconds: 5), // hack to focus after visibility change
        () => FocusScope.of(
          context!,
        ).requestFocus(
          widget.focusNode ?? focusNode,
        ),
      );
    } else {
      FocusScope.of(context!).unfocus();
    }
  }

  onOpenMuteDialog(BuildContext context, _Props props) {
    final defaultPadding = EdgeInsets.symmetric(horizontal: 10);
    showDialog(
      context: context,
      builder: (BuildContext context) => DialogRounded(
        title: 'Mute notifications',
        children: [
          ListTile(
            title: Padding(
                padding: defaultPadding,
                child: Text(
                  'Mute for 1 hour',
                  style: Theme.of(context).textTheme.subtitle1,
                )),
            onTap: () {
              props.onMuteNotifications(Duration(hours: 1));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Padding(
              padding: defaultPadding,
              child: Text(
                'Mute for 8 hours',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            onTap: () {
              props.onMuteNotifications(Duration(hours: 8));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Padding(
              padding: defaultPadding,
              child: Text(
                'Mute for 1 day',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            onTap: () {
              props.onMuteNotifications(Duration(days: 1));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Padding(
              padding: defaultPadding,
              child: Text(
                'Mute for 7 days',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            onTap: () {
              props.onMuteNotifications(Duration(days: 7));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Padding(
              padding: defaultPadding,
              child: Text(
                'Always',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            onTap: () {
              props.onToggleNotifications();
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(store, widget.room.id),
        builder: (context, props) => AppBar(
          titleSpacing: 0.0,
          automaticallyImplyLeading: false,
          systemOverlayStyle: Theme.of(context).appBarTheme.systemOverlayStyle,
          title: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => widget.onBack!(),
                  tooltip: Strings.labelBack,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.chatDetails,
                    arguments: ChatDetailsArguments(
                      roomId: widget.room.id,
                      title: widget.room.name,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'ChatAvatar',
                        child: Avatar(
                          uri: widget.room.avatarUri,
                          size: Dimensions.avatarSizeMin,
                          alt: formatRoomInitials(room: widget.room),
                          background: widget.color,
                        ),
                      ),
                      Visibility(
                        visible: !widget.room.encryptionEnabled,
                        child: Positioned(
                          right: 0,
                          bottom: 0,
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
                        visible: widget.badgesEnabled &&
                            widget.room.type == 'group' &&
                            !widget.room.invite,
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
                        visible: widget.badgesEnabled &&
                            widget.room.type == 'public' &&
                            !widget.room.invite,
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
              ),
              Flexible(
                child: Text(
                  widget.room.name!,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Visibility(
              visible: DEBUG_MODE,
              child: IconButton(
                icon: Icon(Icons.gamepad),
                iconSize: Dimensions.buttonAppBarSize,
                tooltip: 'Debug Room Function',
                color: Colors.white,
                onPressed: () {
                  widget.onDebug!();
                },
              ),
            ),
            RoundedPopupMenu<ChatOptions>(
                onSelected: (ChatOptions result) {
                  switch (result) {
                    case ChatOptions.inviteFriends:
                      Navigator.pushNamed(
                        context,
                        Routes.userInvite,
                        arguments: InviteUsersArguments(
                          roomId: widget.room.id,
                        ),
                      );
                      break;
                    case ChatOptions.chatSettings:
                      Navigator.pushNamed(
                        context,
                        Routes.chatDetails,
                        arguments: ChatDetailsArguments(
                          roomId: widget.room.id,
                          title: widget.room.name,
                        ),
                      );
                      break;
                    case ChatOptions.blockUser:
                      onBlockUser(context: context, props: props);
                      break;
                    case ChatOptions.muteNotifications:
                      onOpenMuteDialog(context, props);
                      break;
                    default:
                      break;
                  }
                },
                icon: Icon(Icons.more_vert, color: Colors.white),
                itemBuilder: (BuildContext context) {
                  final menu = <PopupMenuEntry<ChatOptions>>[
                    const PopupMenuItem<ChatOptions>(
                      enabled: false,
                      value: ChatOptions.search,
                      child: Text('Search'),
                    ),
                    const PopupMenuItem<ChatOptions>(
                      enabled: false,
                      value: ChatOptions.allMedia,
                      child: Text('All Media'),
                    ),
                    const PopupMenuItem<ChatOptions>(
                      value: ChatOptions.chatSettings,
                      child: Text('Chat Settings'),
                    ),
                    const PopupMenuItem<ChatOptions>(
                      value: ChatOptions.inviteFriends,
                      child: Text('Invite Friends'),
                    ),
                    const PopupMenuItem<ChatOptions>(
                      value: ChatOptions.muteNotifications,
                      child: Text('Mute Notifications'),
                    ),
                  ];

                  if (widget.room.direct) {
                    menu.add(const PopupMenuItem<ChatOptions>(
                      value: ChatOptions.blockUser,
                      child: Text('Block User'),
                    ));
                  }

                  return menu;
                })
          ],
        ),
      );
}

class _Props extends Equatable {
  final User currentUser;
  final List<User?> roomUsers;

  final Function onBlockUser;
  final Function onMuteNotifications;
  final Function onToggleNotifications;

  const _Props({
    required this.roomUsers,
    required this.currentUser,
    required this.onBlockUser,
    required this.onMuteNotifications,
    required this.onToggleNotifications,
  });

  @override
  List<Object> get props => [];

  static _Props mapStateToProps(Store<AppState> store, String? roomId) => _Props(
        currentUser: store.state.authStore.user,
        roomUsers: (store.state.roomStore.rooms[roomId]?.userIds ?? [])
            .map((id) => store.state.userStore.users[id])
            .toList(),
        onBlockUser: (String userId) async {
          final user = store.state.userStore.users[userId];
          return await store.dispatch(toggleBlockUser(user: user));
        },
        onMuteNotifications: (Duration duration) {
          store.dispatch(muteChatNotifications(
            roomId: roomId!,
            timestamp: DateTime.now().add(duration).millisecondsSinceEpoch,
          ));
        },
        onToggleNotifications: () {
          store.dispatch(toggleChatNotifications(roomId: roomId!, enabled: false));
        },
      );
}
