import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/events/ephemeral/m.read/model.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/message.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:intl/intl.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class MessageDetailArguments {
  final String roomId;
  final Message message;

  // Improve loading times
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
    ReadStatus readStatus = props.messageReads[message.id];

    Map<String, int> userTimestamps =
        readStatus != null ? readStatus.userReads : Map<String, int>();
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
          print('[buildUserReadList] $error');
        }
        return ListTile(
          dense: true,
          contentPadding: contentPadding,
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
        converter: (Store<AppState> store) => Props.mapStoreToProps(
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
                  child: MessageWidget(
                    message: message,
                    isUserSent: isUserSent,
                    messageOnly: true,
                    theme: props.theme,
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: contentPadding,
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
                  contentPadding: contentPadding,
                  title: Text(
                    'Received',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      'TODO',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: contentPadding,
                  title: Text(
                    'Via',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Container(
                    child: Text(
                      'TODO',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  contentPadding: contentPadding,
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
  final Map<String, ReadStatus> messageReads;

  Props({
    @required this.loading,
    @required this.userId,
    @required this.theme,
    @required this.messageReads,
  });

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
    String roomId,
  ) =>
      Props(
        messageReads: store.state.roomStore.rooms[roomId].messageReads ??
            Map<String, ReadStatus>(),
        userId: store.state.userStore.user.userId,
        theme: store.state.settingsStore.theme,
      );

  @override
  List<Object> get props => [
        userId,
        theme,
      ];
}
