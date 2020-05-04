import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:Tether/global/notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';

const tether_service_id = 256;
const tether_service_debug_id = 244;

void backgroundSync() async {
  final int isolateId = Isolate.current.hashCode;
  final int syncInterval = 2;
  final int secondsTimeout = 60;

  FlutterLocalNotificationsPlugin pluginInstance = await initNotifications(
    onSelectNotification: (String payload) {
      print('Isolate Notification was opened ${payload}');
    },
  );

  showBackgroundServiceNotification(
    notificationId: tether_service_id,
    debugContent: DateFormat('E h:mm ss a').format(DateTime.now()),
    pluginInstance: pluginInstance,
  );

  for (int i = 0; i < secondsTimeout; i++) {
    if (i % syncInterval == 0) {
      Timer(Duration(seconds: i), () async {
        final DateTime now = DateTime.now();
        print(
          "[AndroidAlarmService] running $i timestamp=$now isolate=${isolateId}",
        );

        // TODO: fetchSync here and check for new messages,
        // TODO: save an alternate lastSince for the background service only

        /**
         * Check last since and see if any new messages arrived in the payload
         * No need to update the hive store for now, just do not save the lastSince
         * and the next foreground fetchSync will update the state
         */

        if (i == 30) {
          showMessageNotification(
            messageHash: Random.secure().nextInt(20000),
            pluginInstance: pluginInstance,
          );
        }
      });
    }
  }
}

void testLocalNotification() async {}

class BackgroundSync {
  static Isolate backgroundIsolate;

  static Future<bool> init() async {
    return await AndroidAlarmManager.initialize();
  }

  static void start() async {
    print('[BackgroundSync] starting "tether_hello_service_id"');
    await AndroidAlarmManager.periodic(
      const Duration(seconds: 5),
      tether_service_id,
      backgroundSync,
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );
  }

  static void stop() async {
    try {
      final successfullyCanceled =
          await AndroidAlarmManager.cancel(tether_service_id);
      print(
        '[BackgroundSync] stopped $tether_service_id $successfullyCanceled',
      );

      final andAgain =
          await AndroidAlarmManager.cancel(tether_service_debug_id);

      print(
        '[BackgroundSync] stopped $andAgain $successfullyCanceled',
      );
    } catch (error) {
      print('[stopBackgroundSync] $error');
    }
  }
}
