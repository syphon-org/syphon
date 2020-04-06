import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<FlutterLocalNotificationsPlugin> initNotifications({
  Function onDidReceiveLocalNotification,
  Function onSelectNotification,
}) async {
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  var initializationSettingsIOS = IOSInitializationSettings(
    // requestSoundPermission: false,
    // requestBadgePermission: false,
    // requestAlertPermission: false,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  var initializationSettings = InitializationSettings(
    initializationSettingsAndroid,
    initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onSelectNotification: onSelectNotification,
  );

  return flutterLocalNotificationsPlugin;
}

Future showMessageNotification({int messageHash, String content}) async {
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

  await flutterLocalNotificationsPlugin.show(
    messageHash,
    'New Message',
    content ?? 'Tap to open message',
    platformChannelSpecifics,
  );
}

Future showDebugNotification() async {
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

  Timer(Duration(seconds: 5), () async {
    await flutterLocalNotificationsPlugin.show(
      0,
      'Debug Regular Notifcation',
      'This is a test for styling notifications',
      platformChannelSpecifics,
    );
  });
}
