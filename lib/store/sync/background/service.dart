import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/store/sync/services.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';

/**
 * Background Sync Service (Android Only)
 * static class for managing service through app lifecycle
 */
class BackgroundSync {
  static const service_id = 255;
  static const service_interval = 55;
  static const service_duration = Duration(seconds: service_interval);

  static Isolate backgroundIsolate;

  static Future<bool> init() async {
    return await AndroidAlarmManager.initialize();
  }

  static void start({
    String protocol,
    String homeserver,
    String accessToken,
    String lastSince,
  }) async {
    if (!Platform.isAndroid) {
      print(
        '[BackgroundSync] Failed initialization due to non-android platform :(',
      );
      return;
    }

    print('[BackgroundSync] Starting Background Sync Service');
    final backgroundServiceHive = await openHiveBackgroundUnsafe();

    await backgroundServiceHive.put(Cache.protocol, protocol);
    await backgroundServiceHive.put(Cache.homeserver, homeserver);
    await backgroundServiceHive.put(Cache.accessTokenKey, accessToken);
    await backgroundServiceHive.put(Cache.lastSinceKey, lastSince);

    await AndroidAlarmManager.periodic(
      service_duration,
      service_id,
      notificationSyncIsolate,
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );

    print('[BackgroundSync] Successfully Initialized');
  }

  static void stop() async {
    try {
      final successfullyCanceled = await AndroidAlarmManager.cancel(service_id);
      print(
        '[BackgroundSync] Successfully Stopped $service_id $successfullyCanceled',
      );
    } catch (error) {
      print('[BackgroundSync] Failed To Stop $error');
    }
  }
}
