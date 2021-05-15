// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/user/model.dart';
import 'package:syphon/views/widgets/lists/list-user-bubbles.dart';
import 'package:syphon/views/widgets/messages/message.dart';

class MessageDetailArguments {
  final String? roomId;
  final Message? message;

  MessageDetailArguments({
    this.message,
    this.roomId,
  });
}

class MessageDetails extends StatelessWidget {
  MessageDetails({Key? key}) : super(key: key);

  @protected
  Widget buildUserReadList(Props props, double width) {
    ReadReceipt readReceipts =
        props.readReceipts[props.message!.id!] ?? ReadReceipt();
    Map<String, int> userReads = readReceipts.userReads ?? Map();

    final List<User?> users = userReads.keys
        .map(
          (userId) => props.users[userId],
        )
        .toList();

    return ListUserBubbles(
      max: 4,
      users: users,
      roomId: props.roomId,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(
          store,
          ModalRoute.of(context)!.settings.arguments as MessageDetailArguments,
        ),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final Message message = props.message!;

          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(message.timestamp!);
          final received = DateTime.fromMillisecondsSinceEpoch(
              message.received ?? message.timestamp!);

          final isUserSent = props.userId == message.sender;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                'Message Details',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: SingleChildScrollView(
                child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                  child: ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(bottom: 4),
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: true,
                    itemCount: 1,
                    scrollDirection: Axis.vertical,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      final current =
                          index == 0 ? message : message.edits[index - 1];
                      return MessageWidget(
                        message: current,
                        isUserSent: isUserSent,
                        messageOnly: true,
                        theme: props.theme,
                        timeFormat: 'full',
                      );
                    },
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Sent',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      DateFormat('MMM d h:mm a').format(timestamp),
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Received',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      DateFormat('MMM d h:mm a').format(received),
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Via',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      'Matrix',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'From',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      message.sender!,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    'Read By',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    constraints: BoxConstraints(
                      maxWidth: width / 2,
                      maxHeight: 100,
                    ),
                    child: buildUserReadList(props, width),
                  ),
                ),
              ],
            )),
          );
        },
      );
}

class Props extends Equatable {
  final String? userId;
  final String? roomId;
  final ThemeType theme;
  final Message? message;
  final Map<String, User> users;
  final Map<String, ReadReceipt> readReceipts;

  Props({
    required this.users,
    required this.theme,
    required this.roomId,
    required this.userId,
    required this.message,
    required this.readReceipts,
  });

  static Props mapStateToProps(
    Store<AppState> store,
    MessageDetailArguments args,
  ) =>
      Props(
        roomId: args.roomId,
        message: args.message,
        users: store.state.userStore.users,
        readReceipts: store.state.eventStore.receipts[args.roomId!] ??
            Map<String, ReadReceipt>(),
        userId: store.state.authStore.user.userId,
        theme: store.state.settingsStore.theme,
      );

  @override
  List<Object?> get props => [
        theme,
        userId,
        readReceipts,
      ];
}
