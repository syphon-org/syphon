import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syphon/global/colors.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/actions.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/theme-settings/selectors.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/home/chat/chat-detail-message-screen.dart';
import 'package:syphon/views/navigation.dart';

class AppBarMessageOptions extends StatefulWidget implements PreferredSizeWidget {
  const AppBarMessageOptions({
    Key? key,
    this.title = 'title:',
    this.label = 'label:',
    this.tooltip = 'tooltip:',
    this.room,
    this.message,
    this.brightness = Brightness.dark,
    this.elevation,
    this.focusNode,
    this.isUserSent = false,
    this.onCopy,
    this.onDelete,
    this.onReply,
    this.onEdit,
    this.onDismiss,
    required this.user,
  }) : super(key: key);

  final String title;
  final String label;
  final String tooltip;

  final Room? room;
  final User user;

  final bool isUserSent;

  final Message? message;
  final double? elevation;
  final Brightness brightness;
  final FocusNode? focusNode;

  final Function? onCopy;
  final Function? onEdit;
  final Function? onReply;
  final Function? onDelete;
  final Function? onDismiss;

  @override
  AppBarMessageOptionState createState() => AppBarMessageOptionState();

  @override
  Size get preferredSize => AppBar().preferredSize;
}

class AppBarMessageOptionState extends State<AppBarMessageOptions> {
  final focusNode = FocusNode();

  bool searching = false;
  Timer? searchTimeout;

  @override
  void initState() {
    super.initState();
  }

  bool get isMessageDeleted => widget.message?.body?.isNotEmpty ?? true;

  @override
  Widget build(BuildContext context) => AppBar(
        systemOverlayStyle: computeSystemUIColor(context),
        backgroundColor: Color(AppColors.greyDefault),
        automaticallyImplyLeading: false,
        titleSpacing: 0.0,
        title: Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 8),
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Colors.white,
                ),
                tooltip: Strings.labelBack,
                onPressed: () {
                  widget.onDismiss?.call();
                },
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            tooltip: 'Message Details',
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.messageDetails,
                arguments: MessageDetailArguments(
                  roomId: widget.room!.id,
                  message: widget.message,
                ),
              );

              widget.onDismiss?.call();
            },
          ),
          Visibility(
            visible: isMessageDeleted && widget.isUserSent,
            child: IconButton(
              icon: Icon(Icons.delete),
              iconSize: 28.0,
              tooltip: 'Delete Message',
              color: Colors.white,
              onPressed: () {
                widget.onDelete?.call();
                widget.onDismiss?.call();
              },
            ),
          ),
          Visibility(
            visible: isMessageDeleted && widget.isUserSent,
            child: IconButton(
              icon: Icon(Icons.edit_rounded),
              iconSize: 28.0,
              tooltip: 'Edit Message',
              color: Colors.white,
              onPressed: () {
                widget.onEdit?.call();
              },
            ),
          ),
          Visibility(
            visible: isTextMessage(message: widget.message ?? Message()),
            child: IconButton(
              icon: Icon(Icons.content_copy),
              iconSize: 22.0,
              tooltip: 'Copy Message Content',
              color: Colors.white,
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: widget.message!.formattedBody ?? widget.message!.body,
                  ),
                );

                widget.onDismiss?.call();
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.reply),
            iconSize: 28.0,
            tooltip: 'Quote and Reply',
            color: Colors.white,
            onPressed: () async {
              final store = StoreProvider.of<AppState>(context);
              final roomId = widget.message!.roomId!;

              store.dispatch(selectReply(roomId: roomId, message: widget.message));

              widget.onDismiss?.call();

              widget.onReply?.call();
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            iconSize: 24.0,
            tooltip: 'Share Chats',
            color: Colors.white,
            onPressed: () {
              final room = widget.message!.roomId!;
              final message = widget.message!.id!;
              Share.share('https://matrix.to/#/$room/$message');
            },
          ),
        ],
      );
}
