// Dart imports:
import 'dart:async';
import 'dart:io';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Project imports:
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';

/**
 * Notifications are handled by APNS when running in iOS
 * Only need to handle local notifications on desktop and android 
 *  https://matrix.org/docs/spec/client_server/latest#id470
 */

// TODO: extract apns and re-enable
// import 'package:flutter_apns/apns.dart';
// import 'package:flutter_apns/apns_connector.dart';

// PushConnector connector;

FlutterLocalNotificationsPlugin? globalNotificationPluginInstance;

Future<FlutterLocalNotificationsPlugin> initNotifications({
  Function? onLaunch,
  Function? onResume,
  Function? onMessage,
  Function? onSaveToken,
  Future<dynamic> Function(String?)? onSelectNotification,
  Future<dynamic> Function(int, String?, String?, String?)?
      onDidReceiveLocalNotification,
}) async {
// ic_launcher_foreground needs to be a added as a drawable resource to the root Android project
  var initializationSettingsAndroid = AndroidInitializationSettings(
    'ic_launcher_foreground',
  );

  var initializationSettingsIOS = IOSInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  var initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
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
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  final result = await pluginInstance!
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()!
      .requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

  // TODO: extract ios only apns and reenable
  // if (Platform.isIOS && connector != null) {
  //   connector.requestNotificationPermissions();
  // }
  //

  // result means it's not needed, since it's iOS only
  return Future.value(result);
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
  int notificationId = 0,
  String debugContent = '',
  FlutterLocalNotificationsPlugin? pluginInstance,
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
    importance: Importance.none,
    priority: Priority.min,
    visibility: NotificationVisibility.secret,
  );

  final platformChannelSpecifics = new NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  var backgroundNotificationContent =
      '${Strings.contentNotificationBackgroundService}';

  await pluginInstance?.show(
    notificationId,
    Values.default_channel_title,
    backgroundNotificationContent,
    platformChannelSpecifics,
  );
}

Future showMessageNotification({
  int messageHash = 0,
  String? body,
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    Values.channel_description,
    groupKey: Values.channel_group_key,
    priority: Priority.high,
    importance: Importance.defaultImportance,
    visibility: NotificationVisibility.private,
  );

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  await pluginInstance?.show(
    messageHash,
    'New Message',
    body ?? 'Tap to open message',
    platformChannelSpecifics,
  );
}

Future showDebugNotification({
  int notificationId = 0,
  String customMessage = 'Example Notification',
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    Values.channel_description,
    importance: Importance.defaultImportance,
    priority: Priority.high,
  );

  final platformChannelSpecifics = new NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );

  // Timer(Duration(seconds: 5), () async {
  await pluginInstance?.show(
    notificationId,
    'Debug Regular Notifcation',
    customMessage,
    platformChannelSpecifics,
  );
  // });
}

void dismissAllNotifications({
  FlutterLocalNotificationsPlugin? pluginInstance,
}) {
  pluginInstance?.cancelAll();
}
