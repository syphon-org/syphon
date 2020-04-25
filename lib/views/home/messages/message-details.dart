import 'package:Tether/store/index.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/themes.dart';
import 'package:Tether/views/widgets/message.dart';
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

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          double width = MediaQuery.of(context).size.width;
          final contentPadding =
              EdgeInsets.symmetric(horizontal: 24, vertical: 8);
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
                      DateFormat.EEEE().format(timestamp),
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
                      'TODO',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ],
            )),
          );
        },
      );
}

class Props {
  final bool loading;
  final String userId;
  final ThemeType theme;

  Props({
    @required this.loading,
    @required this.userId,
    @required this.theme,
  });

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
        loading: store.state.roomStore.syncing || store.state.roomStore.loading,
        userId: store.state.userStore.user.userId,
        theme: store.state.settingsStore.theme,
      );

  @override
  int get hashCode => loading.hashCode ^ userId.hashCode ^ theme.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          theme == other.theme &&
          userId == other.userId &&
          loading == other.loading;
}
