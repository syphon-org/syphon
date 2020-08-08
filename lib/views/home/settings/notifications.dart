// Dart imports:
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:equatable/equatable.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

// Project imports:
import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

final String debug = DotEnv().env['DEBUG'];

class NotificationSettingsView extends StatelessWidget {
  NotificationSettingsView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, Props>(
        converter: (Store<AppState> store) => Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

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
                CardSection(
                  child: Column(children: [
                    Container(
                      width: width,
                      padding: Dimensions.listPadding,
                      child: Text(
                        'On-Device',
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                    Container(
                      width: width,
                      padding: Dimensions.listPadding,
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          text: 'Show notifications using a background service',
                          style: Theme.of(context).textTheme.caption,
                          children: <TextSpan>[
                            TextSpan(
                              text: ' without ',
                              style:
                                  Theme.of(context).textTheme.caption.copyWith(
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
                      onTap: () => props.onToggleLocalNotifications(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      trailing: Container(
                        child: Switch(
                          value: props.localNotificationsEnabled,
                          onChanged: !Platform.isAndroid
                              ? null
                              : (value) => props.onToggleLocalNotifications(),
                        ),
                      ),
                    ),
                  ]),
                ),
                CardSection(
                  child: Column(children: [
                    Container(
                      width: width,
                      padding: Dimensions.listPadding,
                      child: Text(
                        'Matrix (Remote)',
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                    ),
                    Container(
                      width: width,
                      padding: Dimensions.listPadding,
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
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Notifications',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      trailing: Container(
                        child: Switch(
                          value: props.remoteNotificationsEnabled,
                          onChanged: !Platform.isIOS
                              ? null
                              : (value) => props.onToggleRemoteNotifications(
                                    context,
                                  ),
                        ),
                      ),
                    ),
                    ListTile(
                      enabled: props.remoteNotificationsEnabled,
                      dense: true,
                      onTap: () => props.onTogglePusher(),
                      contentPadding: Dimensions.listPadding,
                      title: Text(
                        'Fetch Notifications',
                        style: TextStyle(fontSize: 18.0),
                      ),
                      trailing: Container(
                        child: Switch(
                          value: props.httpPusherEnabled,
                          onChanged: !props.remoteNotificationsEnabled
                              ? null
                              : (value) => props.onTogglePusher(),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            )),
          );
        },
      );
}

class Props extends Equatable {
  final bool httpPusherEnabled;
  final bool localNotificationsEnabled;
  final bool remoteNotificationsEnabled;

  final Function onToggleLocalNotifications;
  final Function onToggleRemoteNotifications;
  final Function onTogglePusher;

  Props({
    @required this.localNotificationsEnabled,
    @required this.remoteNotificationsEnabled,
    @required this.httpPusherEnabled,
    @required this.onToggleLocalNotifications,
    @required this.onToggleRemoteNotifications,
    @required this.onTogglePusher,
  });

  @override
  List<Object> get props => [
        localNotificationsEnabled,
        remoteNotificationsEnabled,
        httpPusherEnabled,
      ];

  static Props mapStateToProps(
    Store<AppState> store,
  ) =>
      Props(
        localNotificationsEnabled: Platform.isAndroid &&
            store.state.settingsStore.notificationsEnabled,
        remoteNotificationsEnabled:
            Platform.isIOS && store.state.settingsStore.notificationsEnabled,
        httpPusherEnabled:
            store.state.settingsStore.notificationSettings != null,
        onToggleLocalNotifications: () {
          store.dispatch(toggleNotifications());
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
                    Strings.confirmationNotifications,
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
                      onPressed: () async {
                        await store.dispatch(toggleNotifications());
                        await store.dispatch(saveNotificationPusher());
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
              return;
            }

            // Otherwise, attempt the toggle
            store.dispatch(saveNotificationPusher(erase: true));
            store.dispatch(toggleNotifications());
          } catch (error) {
            debugPrint('[onToggleRemoteNotifications] $error');
          }
        },
        onTogglePusher: () async {
          // await store.dispatch(fetchNotificationPushers());
          store.dispatch(fetchNotifications());
        },
      );
}
