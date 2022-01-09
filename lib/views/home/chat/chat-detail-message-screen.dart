import 'package:equatable/equatable.dart';

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/store/events/receipts/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/models.dart';
import 'package:syphon/store/settings/theme-settings/model.dart';
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

class MessageDetailsScreen extends StatelessWidget {
  const MessageDetailsScreen({Key? key}) : super(key: key);

  @protected
  Widget buildUserReadList(_Props props, double width) {
    final Receipt readReceipts = props.readReceipts[props.message!.id!] ?? Receipt();
    final userReads = Map<String, int>.from(readReceipts.userReads);

    final List<User?> users = userReads.keys.map((userId) => props.users[userId]).toList();

    return ListUserBubbles(
      max: 4,
      users: users,
      roomId: props.roomId,
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        distinct: true,
        converter: (Store<AppState> store) => _Props.mapStateToProps(
          store,
          ModalRoute.of(context)!.settings.arguments as MessageDetailArguments,
        ),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;
          final Message message = props.message!;

          final timestamp = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
          final received = DateTime.fromMillisecondsSinceEpoch(
            message.received == 0 ? message.timestamp : message.received,
          );

          final isUserSent = props.userId == message.sender;

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                Strings.titleMessageDetails,
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
                    // ignore: avoid_redundant_argument_values
                    scrollDirection: Axis.vertical,
                    // ignore: avoid_redundant_argument_values
                    addRepaintBoundaries: true,
                    // ignore: avoid_redundant_argument_values
                    addAutomaticKeepAlives: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 1,
                    itemBuilder: (BuildContext context, int index) => MessageWidget(
                      message: message,
                      isUserSent: isUserSent,
                      messageOnly: true,
                      themeType: props.themeType,
                      timeFormat: TimeFormat.full,
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemSent,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    DateFormat('MMM d h:mm a').format(timestamp),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemReceived,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    DateFormat('MMM d h:mm a').format(received),
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemVia,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    'Matrix',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemFrom,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Text(
                    message.sender!,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                ListTile(
                  contentPadding: Dimensions.listPadding,
                  title: Text(
                    Strings.listItemReadBy,
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

class _Props extends Equatable {
  final String? userId;
  final String? roomId;
  final Message? message;
  final ThemeType themeType;
  final TimeFormat timeFormat;
  final Map<String, User> users;
  final Map<String, Receipt> readReceipts;

  const _Props({
    required this.users,
    required this.roomId,
    required this.userId,
    required this.message,
    required this.themeType,
    required this.timeFormat,
    required this.readReceipts,
  });

  static _Props mapStateToProps(
    Store<AppState> store,
    MessageDetailArguments args,
  ) =>
      _Props(
        roomId: args.roomId,
        message: args.message,
        users: store.state.userStore.users,
        readReceipts: store.state.eventStore.receipts[args.roomId!] ?? <String, Receipt>{},
        userId: store.state.authStore.user.userId,
        themeType: store.state.settingsStore.themeSettings.themeType,
        timeFormat:
            store.state.settingsStore.timeFormat24Enabled ? TimeFormat.hr24 : TimeFormat.hr12,
      );

  @override
  List<Object?> get props => [
        themeType,
        userId,
        readReceipts,
      ];
}
