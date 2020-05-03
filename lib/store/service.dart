import 'dart:isolate';

import 'package:Tether/global/notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const tether_service_id = 256;
const room_observer_id = 100;

/* ****************************** NEW ****************************** */

void testingHello() {
  final int isolateId = Isolate.current.hashCode;
  final DateTime now = DateTime.now();

  print(
    "[AndroidAlarmService] timestamp=$now isolate=${isolateId} function='$testingHello'",
  );
}

void testLocalNotification() async {
  FlutterLocalNotificationsPlugin pluginInstance = await initNotifications(
    onSelectNotification: (String payload) {
      print('Isolate Notification was opened ${payload}');
    },
  );
  showDebugNotification(pluginInstance: pluginInstance);
}

class BackgroundSync {
  static Isolate backgroundIsolate;

  static Future<bool> init() async {
    return await AndroidAlarmManager.initialize();
  }

  static void start() async {
    // await AndroidAlarmManager.periodic(
    //   const Duration(seconds: 2),
    //   tether_service_id,
    //   testLocalNotification,
    //   exact: true,
    // );
    await AndroidAlarmManager.oneShot(
      const Duration(seconds: 5),
      tether_service_id,
      testLocalNotification,
      exact: true,
    );
  }

  static void stop() async {
    try {
      final successfullyCanceled =
          await AndroidAlarmManager.cancel(tether_service_id);
      print(
        '[stopBackgroundSync] (tether service) successfully canceled $successfullyCanceled',
      );
      final anotherOne = await AndroidAlarmManager.cancel(room_observer_id);

      print(
        '[stopBackgroundSync] (original service) successfully canceled $anotherOne',
      );
    } catch (error) {
      print('[stopBackgroundSync] $error');
    }
  }
}

/* ****************************** OLD ****************************** */

/**
 * startRoomObserverService
 * 
 */
void startRoomObserverService() async {
  await AndroidAlarmManager.initialize();

  await AndroidAlarmManager.periodic(
    const Duration(seconds: 5),
    room_observer_id,
    testingHello,
  );
}
