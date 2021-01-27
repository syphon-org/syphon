// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/themes.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/events/ephemeral/m.read/model.dart';
import 'package:syphon/store/events/messages/model.dart';
import 'package:syphon/views/widgets/messages/message.dart';

final String debug = DotEnv().env['DEBUG'];

class MessageDetailArguments {
  final String roomId;
  final Message message;

  MessageDetailArguments({
    this.message,
    this.roomId,
  });
}

class MessageDetails extends StatelessWidget {
  MessageDetails({Key key}) : super(key: key);

  final contentPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 8);

  @protected
  Widget buildUserReadList(Props props, Message message) {
    ReadReceipt readReceipts = props.readReceipts[message.id];

    Map<String, int> userTimestamps =
        readReceipts != null ? readReceipts.userReads : Map<String, int>();
    final List<String> users = userTimestamps.keys.toList();

    return ListView.builder(
      itemCount: users.length,
      shrinkWrap: true,
      scrollDirection: Axis.vertical,
      itemBuilder: (BuildContext context, int index) {
        var timestamp = DateTime.now();
        try {
          timestamp = DateTime.fromMillisecondsSinceEpoch(
            userTimestamps[users[index]],
          );
        } catch (error) {
          debugPrint('[buildUserReadList] $error');
        }
        return ListTile(
          dense: true,
          contentPadding: Dimensions.listPadding,
          title: Text(
            users[index],
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        distinct: true,
        converter: (Store<AppState> store) => Props.mapStateToProps(
          store,
          (ModalRoute.of(context).settings.arguments as MessageDetailArguments)
              .roomId,
        ),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          final Message message = (ModalRoute.of(context).settings.arguments
                  as MessageDetailArguments)
              .message;
          final timestamp =
              DateTime.fromMillisecondsSinceEpoch(message.timestamp);
          final received = DateTime.fromMillisecondsSinceEpoch(
              message.received ?? message.timestamp);

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
            body: Container(
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
                      message.sender,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: 500,
                  ),
                  child: buildUserReadList(props, message),
                )
              ],
            )),
          );
        },
      );
}

class Props extends Equatable {
  final bool loading;
  final String userId;
  final ThemeType theme;
  final Map<String, ReadReceipt> readReceipts;

  Props({
    @required this.loading,
    @required this.userId,
    @required this.theme,
    @required this.readReceipts,
  });

  static Props mapStateToProps(
    Store<AppState> store,
    String roomId,
  ) =>
      Props(
        readReceipts: store.state.roomStore.rooms[roomId].readReceipts ??
            Map<String, ReadReceipt>(),
        userId: store.state.authStore.user.userId,
        theme: store.state.settingsStore.theme,
      );

  @override
  List<Object> get props => [
        userId,
        theme,
      ];
}
