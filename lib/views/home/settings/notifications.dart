import 'dart:io';

import 'package:Tether/store/index.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:Tether/global/colors.dart';
import 'package:Tether/global/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

final String debug = DotEnv().env['DEBUG'];

class NotificationSettings extends StatelessWidget {
  NotificationSettings({Key key}) : super(key: key);

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

          final sectionBackgroundColor =
              Theme.of(context).brightness == Brightness.dark
                  ? const Color(BASICALLY_BLACK)
                  : const Color(BACKGROUND);

          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
              title: Text(
                'Notifications',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
              ),
            ),
            body: Container(
                child: Column(
              children: <Widget>[
                Card(
                  elevation: 0.5,
                  color: sectionBackgroundColor,
                  margin: EdgeInsets.only(top: 8, bottom: 4),
                  child: Container(
                    padding: EdgeInsets.only(top: 12),
                    child: Column(children: [
                      Container(
                        width: width, // TODO: use flex, i'm rushing
                        padding: contentPadding,
                        child: Text(
                          'On-Device',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                      Container(
                        width: width, // TODO: use flex, i'm rushing
                        padding: contentPadding,
                        child: RichText(
                          textAlign: TextAlign.left,
                          text: TextSpan(
                            text:
                                'Show notifications using a background service',
                            style: Theme.of(context).textTheme.caption,
                            children: <TextSpan>[
                              TextSpan(
                                text: ' without ',
                                style: Theme.of(context)
                                    .textTheme
                                    .caption
                                    .copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              TextSpan(
                                text: 'Google Play Services',
                                style: Theme.of(context).textTheme.caption,
                              ),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        enabled: Platform.isAndroid,
                        dense: true,
                        onTap: () => props.onToggleLocalNotifications(context),
                        contentPadding: contentPadding,
                        title: Text(
                          'Notifications',
                          style: TextStyle(fontSize: 18.0),
                        ),
                        trailing: Container(
                          child: Switch(
                            value: props.notificationsEnabled,
                            onChanged: !Platform.isAndroid
                                ? null
                                : (value) =>
                                    props.onToggleLocalNotifications(context),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                Card(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  elevation: 0.5,
                  color: sectionBackgroundColor,
                  child: Container(
                    padding: EdgeInsets.only(top: 12),
                    child: Column(children: [
                      Container(
                        width: width, // TODO: use flex, i'm rushing
                        padding: contentPadding,
                        child: Text(
                          'Matrix (Remote)',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                      Container(
                        width: width, // TODO: use flex, i'm rushing
                        padding: contentPadding,
                        child: Text(
                          'Show notifications using Apple Push Notifications through Matrix',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.caption,
                        ),
                      ),
                      ListTile(
                        enabled: Platform.isIOS,
                        dense: true,
                        onTap: () => props.onToggleRemoteNotifications(context),
                        contentPadding: contentPadding,
                        title: Text(
                          'Notifications',
                          style: TextStyle(fontSize: 18.0),
                        ),
                        trailing: Container(
                          child: Switch(
                            value: props.notificationsEnabled,
                            onChanged: !Platform.isIOS
                                ? null
                                : (value) => props.onToggleRemoteNotifications(
                                      context,
                                    ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            )),
          );
        },
      );
}

class Props {
  final bool notificationsEnabled;
  final Function onToggleLocalNotifications;
  final Function onToggleRemoteNotifications;

  Props({
    @required this.notificationsEnabled,
    @required this.onToggleLocalNotifications,
    @required this.onToggleRemoteNotifications,
  });

  /* effectively mapStateToProps, but includes functions */
  static Props mapStoreToProps(
    Store<AppState> store,
  ) =>
      Props(
          notificationsEnabled: store.state.settingsStore.notificationsEnabled,
          onToggleLocalNotifications: () {
            store.dispatch(toggleNotifications());
            // TODO: init background service
          },
          onToggleRemoteNotifications: (BuildContext context) {
            try {
              // If the platform is iOS, we'll want to confirm they understand
              // the native notification prompt
              if (Platform.isIOS &&
                  !store.state.settingsStore.notificationsEnabled) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Confirm Notifications"),
                    content: Text(
                      StringStore.notificationConfirmation,
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
                          store.dispatch(toggleNotifications());
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
                return;
              }

              // Otherwise, attempt the toggle
              store.dispatch(toggleNotifications());
            } catch (error) {
              print(error);
            }
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
