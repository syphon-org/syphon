import 'package:Tether/domain/index.dart';
import 'package:Tether/domain/settings/actions.dart';
import 'package:Tether/global/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class NotificationSettings extends StatelessWidget {
  NotificationSettings({Key key}) : super(key: key);

  @protected
  onConfirmToggle({
    context,
    Function onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Notifications"),
        content: Text(
          NOTIFICATION_PROMPT_INFO,
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('No'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          FlatButton(
            child: Text('Sure'),
            onPressed: () {
              if (onConfirm != null) {
                onConfirm();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        converter: (Store<AppState> store) => Props.mapStoreToProps(store),
        builder: (context, props) {
          // Static horizontal: 16, vertical: 8
          final double width = MediaQuery.of(context).size.width;
          final double height = MediaQuery.of(context).size.height;
          final contentPadding = EdgeInsets.symmetric(
            horizontal: width * 0.08,
            vertical: height * 0.01,
          );

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                'Notifications',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w100),
              ),
            ),
            body: Container(
                child: Column(
              children: <Widget>[
                ListTile(
                  dense: true,
                  onTap: () {
                    if (props.notificationsEnabled) {
                      props.onToggleNotifications();
                    } else {
                      onConfirmToggle(
                        context: context,
                        onConfirm: () {
                          props.onToggleNotifications();
                        },
                      );
                    }
                  },
                  contentPadding: contentPadding,
                  title: Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18.0),
                  ),
                  trailing: Container(
                    child: Switch(
                      value: props.notificationsEnabled,
                      onChanged: (value) {
                        if (!value) {
                          props.onToggleNotifications();
                        } else {
                          onConfirmToggle(
                            context: context,
                            onConfirm: () {
                              props.onToggleNotifications();
                            },
                          );
                        }
                      },
                    ),
                  ),
                )
              ],
            )),
          );
        },
      );
}

class Props {
  final bool notificationsEnabled;
  final Function onToggleNotifications;

  Props({
    @required this.notificationsEnabled,
    @required this.onToggleNotifications,
  });

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
          notificationsEnabled: store.state.settingsStore.notificationsEnabled,
          onToggleNotifications: () {
            store.dispatch(toggleNotifications());
          });

  @override
  int get hashCode => notificationsEnabled.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Props &&
          runtimeType == other.runtimeType &&
          notificationsEnabled == other.notificationsEnabled;
}
