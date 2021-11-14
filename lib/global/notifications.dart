import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:syphon/global/print.dart';

import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';

/// Notifications are handled by APNS when running in iOS
/// Only need to handle local notifications on desktop and android
///  https://matrix.org/docs/spec/client_server/latest#id470

// TODO: extract apns and re-enable
// import 'package:flutter_apns/apns.dart';
// import 'package:flutter_apns/apns_connector.dart';

// PushConnector connector;

FlutterLocalNotificationsPlugin? globalNotificationPluginInstance;

Future<FlutterLocalNotificationsPlugin?> initNotifications({
  Function? onLaunch,
  Function? onResume,
  Function? onMessage,
  Function? onSaveToken,
  Future<dynamic> Function(String?)? onSelectNotification,
  Future<dynamic> Function(int, String?, String?, String?)? onDidReceiveLocalNotification,
}) async {
  // Currently mobile only
  if (!(Platform.isIOS || Platform.isAndroid)) {
    return Future.value();
  }

// ic_launcher_foreground needs to be a added as a drawable resource to the root Android project
  final initializationSettingsAndroid = AndroidInitializationSettings(
    'ic_launcher_foreground',
  );

  final initializationSettingsIOS = IOSInitializationSettings(
    requestSoundPermission: false,
    requestBadgePermission: false,
    requestAlertPermission: false,
    onDidReceiveLocalNotification: onDidReceiveLocalNotification,
  );

  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  final FlutterLocalNotificationsPlugin pluginInstance = FlutterLocalNotificationsPlugin();

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

  printInfo('[initNotifications] successfully initialized $pluginInstance');
  return pluginInstance;
}

Future<bool> promptNativeNotificationsRequest({
  required FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  var result;

  if (Platform.isAndroid) {
    result = true;
  }

  if (Platform.isIOS) {
    // TODO: extract ios only apns and reenable
    // if (connector != null) {
    //   connector.requestNotificationPermissions();
    // }
    //

    result = await pluginInstance
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  return Future.value(result);
}

/// Background Service Notification
///
/// NOTE: background connection updates are only available on
/// android. iOS uses APNS to update through push notifications
///
/// This is used in android to circumvent google play services
///
/// If the notification is not reinvoked after 61 seconds the service is
/// likely no longer running and the notification should be automatically
/// dissmissed
Future showBackgroundServiceNotification({
  int notificationId = 0,
  String debugContent = '',
  required FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id_background_service,
    Values.channel_name_background_service,
    channelDescription: Values.channel_description,
    ongoing: true,
    autoCancel: false,
    showWhen: false,
    playSound: false,
    enableVibration: false,
    onlyAlertOnce: true,
    priority: Priority.low,
    importance: Importance.low,
    visibility: NotificationVisibility.private,
    channelShowBadge: false,
    // Timeout if not repeatedly set by the background service
    timeoutAfter: Values.serviceNotificationTimeoutDuration,
  );

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: IOSNotificationDetails(),
  );

  await pluginInstance.show(
    notificationId,
    Values.default_channel_title,
    Strings.alertBackgroundService,
    platformChannelSpecifics,
  );
}

Future showMessageNotification({
  int? id,
  String body = 'Tap to open Message',
  String title = 'New Message',
  StyleType style = StyleType.Itemized,
  Map<String, String> uncheckedMessages = const {},
  required FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  var messageHash = id ?? Random.secure().nextInt(1 << 31);
  var androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    channelDescription: Values.channel_description,
    groupKey: Values.channel_group_key,
    priority: Priority.defaultPriority,
    importance: Importance.defaultImportance,
    visibility: NotificationVisibility.private,
    channelShowBadge: true,
  );

  // For Inbox Style Only
  var payload;

  switch (style) {
    case StyleType.Latest:
      // TODO: allow for grouping / layered notifications here
      messageHash = 0;
      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        Values.channel_id,
        Values.channel_name_messages,
        channelDescription: Values.channel_description,
        groupKey: Values.channel_group_key,
        priority: Priority.defaultPriority,
        importance: Importance.defaultImportance,
        visibility: NotificationVisibility.private,
        setAsGroupSummary: true,
        channelShowBadge: true,
      );
      break;
    case StyleType.Inbox:
      // List<String> lines = <String>[
      //   'ABC 123 Check this out',
      //   'XYZ URI Launch Party'
      // ];
      messageHash = 0;
      final List<String> lines = <String>[];

      for (final notificationBody in uncheckedMessages.values) {
        lines.add(notificationBody);
      }

      final inboxStyleInformation = InboxStyleInformation(
        lines,
        contentTitle: title,
        summaryText: body,
      );

      androidPlatformChannelSpecifics = AndroidNotificationDetails(
        Values.channel_id,
        Values.channel_name_messages,
        channelDescription: Values.channel_description,
        groupKey: Values.channel_group_key,
        priority: Priority.defaultPriority,
        importance: Importance.defaultImportance,
        visibility: NotificationVisibility.private,
        setAsGroupSummary: true,
        channelShowBadge: true,
        styleInformation: inboxStyleInformation,
      );

      payload = jsonEncode({
        'checked': true,
      });
      break;
    default:
      break;
  }

  final platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: IOSNotificationDetails(),
  );

  await pluginInstance.show(
    messageHash,
    title,
    body,
    platformChannelSpecifics,
    payload: payload,
  );
}

///
/// example based on https://developer.android.com/training/notify-user/group.html
///
Future showMessageNotificationTest({
  int messageHash = 0,
  String? body,
  required FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  const String groupKey = 'com.android.example';
  const String groupChannelId = 'grouped channel id';
  const String groupChannelName = 'grouped channel name';
  const String groupChannelDescription = 'grouped channel description';
  final firstNotificationAndroidSpecifics = AndroidNotificationDetails(
    groupChannelId,
    groupChannelName,
    channelDescription: groupChannelDescription,
    setAsGroupSummary: true,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    groupKey: groupKey,
  );

  final firstNotificationPlatformSpecifics = NotificationDetails(
    android: firstNotificationAndroidSpecifics,
  );

  await pluginInstance.show(
    1,
    'XYZ URI',
    'You will not believe...',
    firstNotificationPlatformSpecifics,
  );

  final secondNotificationAndroidSpecifics = AndroidNotificationDetails(
    groupChannelId,
    groupChannelName,
    channelDescription: groupChannelDescription,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    groupKey: groupKey,
  );

  final NotificationDetails secondNotificationPlatformSpecifics =
      NotificationDetails(android: secondNotificationAndroidSpecifics);
  await pluginInstance.show(
    2,
    'ABC 123',
    'Please join us to celebrate the...',
    secondNotificationPlatformSpecifics,
  );

  // Create the summary notification to support older devices that pre-date
  // / Android 7.0 (API level 24).
  // /
  // / Recommended to create this regardless as the behaviour may vary as
  // / mentioned in https://developer.android.com/training/notify-user/group
  const List<String> lines = <String>['ABC 123 Check this out', 'XYZ URI    Launch Party'];
  const InboxStyleInformation inboxStyleInformation =
      InboxStyleInformation(lines, contentTitle: '2 messages', summaryText: 'janedoe@example.com');
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      groupChannelId, groupChannelName,
      channelDescription: groupChannelDescription,
      styleInformation: inboxStyleInformation,
      groupKey: groupKey,
      setAsGroupSummary: true);
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await pluginInstance.show(3, 'Attention', 'Two messages', platformChannelSpecifics);
}

Future showDebugNotification({
  int notificationId = 0,
  String customMessage = 'Example Notification',
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  final iOSPlatformChannelSpecifics = IOSNotificationDetails();

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    Values.channel_id,
    Values.channel_name_messages,
    channelDescription: Values.channel_description,
    importance: Importance.defaultImportance,
    priority: Priority.high,
  );

  final platformChannelSpecifics = NotificationDetails(
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
