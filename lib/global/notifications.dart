import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/**
 * Notifications are handled by APNS when running in iOS
 * Only need to handle local notifications on desktop and android 
 */
// https://matrix.org/docs/spec/client_server/latest#id470

FlutterLocalNotificationsPlugin globalNotificationPluginInstance;

Future<FlutterLocalNotificationsPlugin> initNotifications({
  Function onDidReceiveLocalNotification,
  Function onSelectNotification,
}) async {
  try {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

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
  } catch (error) {
    print('[initNotifications] $error');
  }
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
  int messageHash,
  String content,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = new IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'tether_notifications',
    'Tether',
    'S',
    importance: Importance.Default,
    priority: Priority.High,
  );

  final platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  await pluginInstance.show(
    messageHash,
    'New Message',
    content ?? 'Tap to open message',
    platformChannelSpecifics,
  );
}

Future showDebugNotification({
  String customMessage,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = new IOSNotificationDetails();
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'tether_notifications',
    'Tether',
    'Notifications for tether messenger',
    importance: Importance.Default,
    priority: Priority.High,
  );

  final platformChannelSpecifics = new NotificationDetails(
    androidPlatformChannelSpecifics,
    iOSPlatformChannelSpecifics,
  );

  // Timer(Duration(seconds: 5), () async {
  await pluginInstance.show(
    0,
    'Debug Regular Notifcation',
    customMessage ?? 'This is a test for styling notifications',
    platformChannelSpecifics,
  );
  // });
}
