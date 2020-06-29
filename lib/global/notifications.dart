import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/**
 * Notifications are handled by APNS when running in iOS
 * Only need to handle local notifications on desktop and android 
 *  https://matrix.org/docs/spec/client_server/latest#id470
 */

// TODO: extract apns and re-enable
// import 'package:flutter_apns/apns.dart';
// import 'package:flutter_apns/apns_connector.dart';

// PushConnector connector;

FlutterLocalNotificationsPlugin globalNotificationPluginInstance;

Future<FlutterLocalNotificationsPlugin> initNotifications({
  Function onDidReceiveLocalNotification,
  Function onSelectNotification,
  Function onSaveToken,
  Function onLaunch,
  Function onResume,
  Function onMessage,
}) async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  var initializationSettingsIOS = IOSInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  var initializationSettings = InitializationSettings(
    initializationSettingsAndroid,
    initializationSettingsIOS,
  );

  FlutterLocalNotificationsPlugin pluginInstance =
      FlutterLocalNotificationsPlugin();

  await pluginInstance.initialize(
    initializationSettings,
    onSelectNotification: onSelectNotification,
  );

  if (Platform.isIOS) {
    /** TODO: extract ios only apns and reenable
    connector = createPushConnector();

    connector.configure(
      onLaunch: onLaunch,
      onResume: onResume,
      onMessage: onMessage,
    );

    connector.token.addListener(() {
      if (onSaveToken != null) {
        onSaveToken(connector.token.value);
      }
    });
     */
  }

  debugPrint('[initNotifications] successfully initialized $pluginInstance');
  return pluginInstance;
}

Future<bool> promptNativeNotificationsRequest({
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final result = await pluginInstance
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  /** TODO: extract ios only apns and reenable
  if (Platform.isIOS && connector != null) {
    connector.requestNotificationPermissions();
  } 
   */

  // result means it's not needed, since it's iOS only
  return result == null ? true : result;
}

/**
 * Background Service Notification
 * 
 * NOTE: background connection updates are only available on
 * android. iOS uses APNS to update through push notifications
 * 
 * This is used in android to circumvent google play services
 * 
 * If the notification is not reinvoked after 61 seconds the service is
 * likely no longer running and the notification should be automatically
 * dissmissed
 */
Future showBackgroundServiceNotification({
  int notificationId,
  String debugContent = '',
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id_background_service,
    Values.channel_name_background_service,
    Values.channel_description,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
    timeoutAfter: 65 * 1000, // Timeout if not set further
    importance: Importance.None,
    priority: Priority.Min,
    visibility: NotificationVisibility.Secret,
  );

  final platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  await pluginInstance.show(
    notificationId,
    Values.default_channel_title,
    '${Strings.contentNotificationBackgroundService} $debugContent',
    platformChannelSpecifics,
  );
}

Future showMessageNotification({
  int messageHash = 0,
  String body,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    Values.channel_description,
    priority: Priority.High,
    importance: Importance.Default,
    visibility: NotificationVisibility.Private,
  );

  final platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  await pluginInstance.show(
    messageHash,
    'New Message',
    body ?? 'Tap to open message',
    platformChannelSpecifics,
  );
}

Future showDebugNotification({
  int notificationId,
  String customMessage,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    Values.channel_description,
    importance: Importance.Default,
    priority: Priority.High,
  );

  final platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  // Timer(Duration(seconds: 5), () async {
  await pluginInstance.show(
    notificationId ?? 0,
    'Debug Regular Notifcation',
    customMessage ?? 'This is a test for styling notifications',
    platformChannelSpecifics,
  );
  // });
}

void dismissAllNotifications({
  FlutterLocalNotificationsPlugin pluginInstance,
}) {
  pluginInstance.cancelAll();
}
