// Flutter imports:
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/rooms/room/selectors.dart';
import 'package:syphon/views/home/chat/details-chat.dart';
import 'package:syphon/views/home/chat/index.dart';
import 'package:syphon/views/widgets/avatars/avatar-circle.dart';
import 'package:syphon/views/widgets/containers/menu-rounded.dart';

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
  Widget build(BuildContext context) => AppBar(
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
                      child: AvatarCircle(
                        uri: widget.room.avatarUri,
                        size: Dimensions.avatarSizeMin,
                        alt: formatRoomInitials(room: widget.room),
                        background: widget.color,
                      ),
                    ),
                    Visibility(
                      visible: widget.room.encryptionEnabled,
                      child: Positioned(
                        right: 0,
                        bottom: 0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: Dimensions.badgeAvatarSize,
                            height: Dimensions.badgeAvatarSize,
                            color: Colors.green,
                            child: Icon(
                              Icons.lock,
                              color: Colors.white,
                              size: Dimensions.badgeAvatarSize - 6,
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
                case ChatOptions.chatSettings:
                  return Navigator.pushNamed(
                    context,
                    '/home/chat/settings',
                    arguments: ChatSettingsArguments(
                      roomId: widget.room.id,
                      title: widget.room.name,
                    ),
                  );
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
                enabled: false,
                value: ChatOptions.inviteFriends,
                child: Text('Invite Friends'),
              ),
              const PopupMenuItem<ChatOptions>(
                enabled: false,
                value: ChatOptions.muteNotifications,
                child: Text('Mute Notifications'),
              ),
            ],
          )
        ],
      );
}
