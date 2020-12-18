// Flutter imports:
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/store/user/actions.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/home/groups/invite-users.dart';
import 'package:syphon/views/widgets/avatars/avatar.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';
import 'package:syphon/views/widgets/dialogs/dialog-confirm.dart';

enum ChatOptions {
  search,
  allMedia,
  chatSettings,
  inviteFriends,
  muteNotifications,
  blockUser,
}

class AppBarChat extends StatefulWidget implements PreferredSizeWidget {
  AppBarChat({
    Key key,
    this.title = 'title:',
    this.label = 'label:',
    this.tooltip = 'tooltip:',
    this.room,
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

  final bool loading;
  final bool forceFocus;
  final bool badgesEnabled;
  final Room room;
  final Color color;
  final String title;
  final String label;
  final String tooltip;
  final double elevation;
  final Brightness brightness;
  final FocusNode focusNode;

  final Function onBack;
  final Function onDebug;
  final Function onSearch;
  final Function onToggleSearch;

  @override
  AppBarChatState createState() => AppBarChatState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class AppBarChatState extends State<AppBarChat> {
  final focusNode = FocusNode();

  bool searching = false;
  Timer searchTimeout;

  @override
  void initState() {
    super.initState();

    // NOTE: still needed to have navigator context in dialogs
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (widget.forceFocus) {
        // TODO: implement chat searching
      }
    });
  }

  @protected
  void onBack() {
    if (onBack != null) {
      onBack();
    } else {
      Navigator.pop(context);
    }
  }

  @protected
  void onBlockUser({BuildContext context, _Props props}) async {
    final user = props.roomUsers.firstWhere(
      (user) => user.userId != props.currentUser.userId,
    );
    return await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => DialogConfirm(
        title: "Block User",
        content:
            "If you block ${user.displayName}, you will not be able to see their messages and you will immediately leave this chat.",
        onConfirm: () async {
          await props.blockUser(user.userId);
          Navigator.popUntil(context, (route) => route.isFirst);
        },
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @protected
  void onToggleSearch({BuildContext context}) {
    setState(() {
      searching = !searching;
    });
    if (this.searching) {
      Timer(
        Duration(milliseconds: 5), // hack to focus after visibility change
        () => FocusScope.of(
          context,
        ).requestFocus(
          widget.focusNode ?? focusNode,
        ),
      );
    } else {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) =>
            _Props.mapStateToProps(store, widget.room.id),
        builder: (context, props) => AppBar(
          titleSpacing: 0.0,
          automaticallyImplyLeading: false,
          brightness: Theme.of(context).appBarTheme.brightness,
          title: Row(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => widget.onBack(),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/home/chat/settings',
                    arguments: ChatSettingsArguments(
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
                        tag: "ChatAvatar",
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
                  widget.room.name,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyText1
                      .copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Visibility(
              maintainSize: false,
              visible: DotEnv().env['DEBUG'] == 'true',
              child: IconButton(
                icon: Icon(Icons.gamepad),
                iconSize: Dimensions.buttonAppBarSize,
                tooltip: 'Debug Room Function',
                color: Colors.white,
                onPressed: () {
                  widget.onDebug();
                },
              ),
            ),
            RoundedPopupMenu<ChatOptions>(
              onSelected: (ChatOptions result) {
                switch (result) {
                  case ChatOptions.inviteFriends:
                    Navigator.pushNamed(
                      context,
                      '/home/user/invite',
                      arguments: InviteUsersArguments(
                        roomId: widget.room.id,
                      ),
                    );
                    break;
                  case ChatOptions.chatSettings:
                    Navigator.pushNamed(
                      context,
                      '/home/chat/settings',
                      arguments: ChatSettingsArguments(
                        roomId: widget.room.id,
                        title: widget.room.name,
                      ),
                    );
                    break;
                  case ChatOptions.blockUser:
                    return onBlockUser(context: context, props: props);
                  default:
                    break;
                }
              },
              icon: Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (BuildContext context) =>
                  <PopupMenuEntry<ChatOptions>>[
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
                !widget.room.direct
                    ? null
                    : const PopupMenuItem<ChatOptions>(
                        value: ChatOptions.blockUser,
                        child: Text('Block User'),
                      ),
                const PopupMenuItem<ChatOptions>(
                  enabled: false,
                  value: ChatOptions.muteNotifications,
                  child: Text('Mute Notifications'),
                ),
              ],
            )
          ],
        ),
      );
}

class _Props extends Equatable {
  final User currentUser;
  final List<User> roomUsers;
  final Function blockUser;

  _Props({
    @required this.roomUsers,
    @required this.currentUser,
    @required this.blockUser,
  });

  @override
  List<Object> get props => [];

  static _Props mapStateToProps(Store<AppState> store, String roomId) => _Props(
        currentUser: store.state.authStore.user,
        roomUsers: store.state.roomStore.rooms[roomId].userIds
            .map((id) => store.state.userStore.users[id])
            .toList(),
        blockUser: (String userId) async {
          final user = store.state.userStore.users[userId];
          return await store.dispatch(toggleBlockUser(user: user));
        },
      );
}
