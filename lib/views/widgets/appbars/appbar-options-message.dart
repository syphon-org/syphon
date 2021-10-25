import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syphon/global/colours.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/selectors.dart';
import 'package:syphon/store/rooms/room/model.dart';
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
    this.onCopy,
    this.onDelete,
    this.onDismiss,
    this.user,
  }) : super(key: key);

  final String title;
  final String label;
  final String tooltip;
  final User? user;

  final Room? room;
  final Message? message;
  final double? elevation;
  final Brightness brightness;
  final FocusNode? focusNode;

  final Function? onCopy;
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
  bool visible = true;
  Timer? searchTimeout;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) =>  AppBar(
        brightness: Brightness.dark, // TOOD: this should inherit from theme
        backgroundColor: Color(Colours.greyDefault),
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
                  if (widget.onDismiss != null) {
                    widget.onDismiss!();
                  }
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
                NavigationPaths.messageDetails,
                arguments: MessageDetailArguments(
                  roomId: widget.room!.id,
                  message: widget.message,
                ),
              );

              if (widget.onDismiss != null) {
                widget.onDismiss!();
              }
            },
          ),
          FutureBuilder<bool>(
              future: isMessageDeletable(room: widget.room,
                  message: widget.message, user: widget.user), // async work
              builder: ( context, snapshot)  {
                final deleteButton = IconButton(
                    icon: Icon(Icons.delete),
                    iconSize: 28.0,
                    tooltip: 'Delete Message',
                    color: Colors.white,
                    onPressed: (){
                      if (widget.onDelete != null) {
                        widget.onDelete!();
                      }
                      if (widget.onDismiss != null) {
                        widget.onDismiss!();
                      }
                    }
                );

                if (snapshot.hasData) {
                  return Visibility(visible: snapshot.data!,
                      child: deleteButton);
                }

                return Visibility(visible: false,
                  child: deleteButton,);
              }
          ),
          Visibility(
            visible: isTextMessage(message: widget.message!),
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

                if (widget.onDismiss != null) {
                  widget.onDismiss!();
                }
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.reply),
            iconSize: 28.0,
            tooltip: 'Quote and Reply',
            color: Colors.white,
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.share),
            iconSize: 24.0,
            tooltip: 'Share Chats',
            color: Colors.white,
            onPressed: () {},
          ),
        ],
      );
}
