import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/store/sync/services.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';

/**
 * Background Sync Service (Android Only)
 * static class for managing service through app lifecycle
 */
class BackgroundSync {
  static const service_id = 254;
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
    String currentUser,
  }) async {
    // android only background sync
    if (!Platform.isAndroid) {
      return;
    }

    final backgroundServiceHive = await openHiveBackgroundUnsafe();

    await backgroundServiceHive.put(Cache.fieldProtocol, protocol);
    await backgroundServiceHive.put(Cache.fieldHomeserver, homeserver);
    await backgroundServiceHive.put(Cache.fieldAccessToken, accessToken);
    await backgroundServiceHive.put(Cache.fieldLastSince, lastSince);
    await backgroundServiceHive.put(Cache.fieldCurrentUser, currentUser);

    await AndroidAlarmManager.periodic(
      service_duration,
      service_id,
      notificationSyncIsolate,
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );
  }

  static void stop() async {
    try {
      await AndroidAlarmManager.cancel(service_id);
    } catch (error) {
      debugPrint('[BackgroundSync] Failed To Stop $error');
    }
  }
}
