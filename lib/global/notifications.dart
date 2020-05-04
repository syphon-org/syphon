import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/**
 * Notifications are handled by APNS when running in iOS
 * Only need to handle local notifications on desktop and android 
 */
// https://matrix.org/docs/spec/client_server/latest#id470

const String channel_id = 'tether_notifications';
const String channel_id_background_service = 'tether_background_notification';
const String channel_name = 'Tether';
const String channel_description =
    'Tether messaging client message and status notifications';

FlutterLocalNotificationsPlugin globalNotificationPluginInstance;

Future<FlutterLocalNotificationsPlugin> initNotifications({
  Function onDidReceiveLocalNotification,
  Function onSelectNotification,
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

  print('[initNotifications] successfully initialized $pluginInstance');
  return pluginInstance;
}

// TODO: impliement this? can you disable natively after enabling?
Future<bool> disableNotifications() {
  return Future.value(false);
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

  // result means it's not needed, since it's iOS only
  return result == null ? true : result;
}

Future showMessageNotification({
  int messageHash = 0,
  String body,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    channel_id,
    channel_name,
    channel_description,
    visibility: NotificationVisibility.Private,
    importance: Importance.Default,
    priority: Priority.High,
  );

  final platformChannelSpecifics = NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  await pluginInstance.show(
    messageHash,
    'New Message',
    body ?? messageHash.toString() ?? 'Tap to open message',
    platformChannelSpecifics,
  );
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
    channel_id_background_service,
    channel_name,
    channel_description,
    timeoutAfter: 120 * 1000, // 61 seconds
    importance: Importance.Max,
    priority: Priority.High,
  );

  final platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  await pluginInstance.show(
    notificationId,
    'Tether',
    'Background connection enabled $debugContent',
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
    channel_id,
    channel_name,
    channel_description,
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
