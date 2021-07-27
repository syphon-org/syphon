import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:equatable/equatable.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:syphon/global/algos.dart';

import 'package:syphon/global/dimensions.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/strings.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syphon/global/string-keys.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/remote/actions.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:syphon/views/widgets/containers/card-section.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  Future onToggleNotifications(_Props props) async {
    final enabledPreviously = props.localNotificationsEnabled;
    await props.onToggleLocalNotifications();
    if (enabledPreviously) {
      BackgroundSync.stop();
      dismissAllNotifications(pluginInstance: globalNotificationPluginInstance);
    }
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
        converter: (Store<AppState> store) => _Props.mapStateToProps(store),
        builder: (context, props) {
          final double width = MediaQuery.of(context).size.width;

          String styleTypeDescription;

          switch (props.styleType) {
            case StyleType.Inbox:
              styleTypeDescription = 'Notification content is formatted together within one notification';
              break;
            case StyleType.Latest:
              styleTypeDescription = 'Notifications will only show one for the most recent notification';
              // styleTypeDescription =
              //     'Notifications will stack overtop of each other until all are dismissed';
              break;
            case StyleType.Itemized:
            default:
              styleTypeDescription = 'A new notification will appear for every notification';
              break;
          }

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
            body: Column(
              children: <Widget>[
                Visibility(
                  visible: Platform.isAndroid || Platform.isMacOS || Platform.isLinux,
                  child: CardSection(
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
                                style: Theme.of(context).textTheme.caption!.copyWith(
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
                        dense: true,
                        onTap: () => props.onToggleLocalNotifications(),
                        contentPadding: Dimensions.listPadding,
                        title: Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.bodyText2,
                        ),
                        trailing: Switch(
                          value: props.localNotificationsEnabled,
                          onChanged: (value) => onToggleNotifications(props),
                        ),
                      ),
                    ]),
                  ),
                ),
                Visibility(
                  visible: Platform.isIOS,
                  child: CardSection(
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
                        trailing: Switch(
                          value: props.remoteNotificationsEnabled,
                          onChanged: !Platform.isIOS
                              ? null
                              : (value) => props.onToggleRemoteNotifications(
                                    context,
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
                        trailing: Switch(
                          value: props.httpPusherEnabled,
                          onChanged:
                              !props.remoteNotificationsEnabled ? null : (value) => props.onTogglePusher(),
                        ),
                      ),
                    ]),
                  ),
                ),
                CardSection(
                  child: Column(
                    children: [
                      Container(
                        width: width,
                        padding: Dimensions.listPadding,
                        child: Text(
                          'Options',
                          textAlign: TextAlign.start,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                      ),
                      ListTile(
                        onTap: !props.localNotificationsEnabled ? null : () => props.onIncrementStyleType(),
                        contentPadding: Dimensions.listPadding,
                        title: Text('Notification Type'),
                        subtitle: Text(
                          styleTypeDescription,
                          style: Theme.of(context).textTheme.caption,
                        ),
                        trailing: Text(enumToString(props.styleType)),
                      ),
                      ListTile(
                        onTap: !props.localNotificationsEnabled ? null : () => props.onIncrementToggleType(),
                        contentPadding: Dimensions.listPadding,
                        title: Text('Notification Default'),
                        subtitle: Text(
                          props.toggleType == ToggleType.Enabled
                              ? 'All chats have notifications enabled by default'
                              : 'All chats have notifications disabled by default',
                          style: Theme.of(context).textTheme.caption,
                        ),
                        trailing: Text(enumToString(props.toggleType)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _Props extends Equatable {
  final bool httpPusherEnabled;
  final bool localNotificationsEnabled;
  final bool remoteNotificationsEnabled;

  final StyleType styleType;
  final ToggleType toggleType;

  final Function onIncrementStyleType;
  final Function onIncrementToggleType;

  final Function onToggleLocalNotifications;
  final Function onToggleRemoteNotifications;
  final Function onTogglePusher;

  const _Props({
    required this.localNotificationsEnabled,
    required this.remoteNotificationsEnabled,
    required this.httpPusherEnabled,
    required this.onToggleLocalNotifications,
    required this.onToggleRemoteNotifications,
    required this.onTogglePusher,
    required this.styleType,
    required this.toggleType,
    required this.onIncrementStyleType,
    required this.onIncrementToggleType,
  });

  @override
  List<Object> get props => [
        localNotificationsEnabled,
        remoteNotificationsEnabled,
        httpPusherEnabled,
        styleType,
        toggleType,
      ];

  static _Props mapStateToProps(
    Store<AppState> store,
  ) =>
      _Props(
        // will not always be platform dependent
        localNotificationsEnabled:
            Platform.isAndroid && store.state.settingsStore.notificationSettings.enabled,
        remoteNotificationsEnabled: Platform.isIOS && store.state.settingsStore.notificationSettings.enabled,
        styleType: store.state.settingsStore.notificationSettings.styleType,
        toggleType: store.state.settingsStore.notificationSettings.toggleType,
        httpPusherEnabled: store.state.settingsStore.notificationSettings.pushers.isNotEmpty,
        onTogglePusher: () async {
          // await store.dispatch(fetchNotificationPushers());
          store.dispatch(fetchNotifications());
        },
        onToggleLocalNotifications: () {
          return store.dispatch(toggleNotifications());
        },
        onIncrementStyleType: () {
          return store.dispatch(incrementStyleType());
        },
        onIncrementToggleType: () {
          return store.dispatch(incrementToggleType());
        },
        onToggleRemoteNotifications: (BuildContext context) {
          try {
            // If the platform is iOS, we'll want to confirm they understand
            // the native notification prompt
            if (Platform.isIOS && !store.state.settingsStore.notificationSettings.enabled) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Notifications'),
                  content: Text(
                    Strings.confirmationNotifications,
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('No'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await store.dispatch(toggleNotifications());
                        await store.dispatch(saveNotificationPusher());
                        Navigator.of(context).pop();
                      },
                      child: Text('Sure'),
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
      );
}
