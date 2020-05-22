import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:Tether/global/libs/hive/index.dart';
import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:hive/hive.dart';

import 'package:Tether/global/notifications.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

const tether_service_id = 255;
const service_interval = Duration(seconds: 5);

/**
 * Background Sync Service (Android Only)
 * static class for managing service through app lifecycle
 */
class BackgroundSync {
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
    await backgroundServiceHive.put(Cache.accessTokenKey, accessToken);

    await AndroidAlarmManager.periodic(
      service_interval,
      tether_service_id,
      backgroundSyncJob,
      rescheduleOnReboot: true,
      exact: true,
      wakeup: true,
    );

    print('[BackgroundSync] Successfully Initialized');
  }

  static void stop() async {
    try {
      final successfullyCanceled =
          await AndroidAlarmManager.cancel(tether_service_id);
      print(
        '[BackgroundSync] Successfully Stopped $tether_service_id $successfullyCanceled',
      );
    } catch (error) {
      print('[BackgroundSync] Failed To Stop $error');
    }
  }
}

/**
 * Background Sync Job (Android Only)
 * 
 * Fetches data from matrix in background and displays
 * notifications without needing google play services
 * 
 * NOTE: https://github.com/flutter/flutter/issues/32164
 */
void backgroundSyncJob() async {
  try {
    const int syncInterval = 30;
    const int secondsTimeout = 60;
    final int isolateId = Isolate.current.hashCode;

    // Init storage location
    var storageLocation;
    try {
      storageLocation = await getApplicationDocumentsDirectory();
    } catch (error) {
      print('[initHiveStorage] storage location failure - $error');
    }

    // Init hive cache + adapters
    Hive.init(storageLocation.path);
    Box backgroundCache = await Hive.openBox(Cache.backgroundKeyUNSAFE);

    final String protocol = 'https://';
    final String homeserver = 'matrix.org';
    final String accessToken = backgroundCache.get(Cache.accessTokenKey);
    final String lastSince = backgroundCache.get(Cache.lastSinceKey);

    FlutterLocalNotificationsPlugin pluginInstance = await initNotifications();

    if (accessToken == null) {
      print('[backgroundSync] Sync Failure (No Access Token Provided)');
      return;
    }

    showBackgroundServiceNotification(
      notificationId: tether_service_id,
      debugContent: DateFormat('E h:mm:ss a').format(DateTime.now()),
      pluginInstance: pluginInstance,
    );

    for (int i = 0; i < secondsTimeout; i++) {
      if (i % syncInterval == 0) {
        Timer(Duration(seconds: i), () async {
          try {
            // Check isolate id and maybe see if a new one is created
            print(
              "[AndroidAlarmService] ($isolateId) Running Fetch Sync $i timestamp=${DateTime.now()}",
            );

            /**
             * Check last since and see if any new messages arrived in the payload
             * No need to update the hive store for now, just do not save the lastSince
             * to the store and the next foreground fetchSync will update the state
             */

            print(
              "[AndroidAlarmService] sync running",
            );
            final data = await MatrixApi.sync(
              protocol: protocol,
              homeserver: homeserver,
              accessToken: accessToken,
              since: lastSince,
            );

            print(
              "[AndroidAlarmService] sync completed",
            );

            final Map<String, dynamic> rawRooms = data['rooms']['join'];

            rawRooms.forEach((roomId, room) {
              /**
              *TODO: Need to handle group / bigger room chats differently than direct chats
              */
              final List<dynamic> timelineEvents = room['timeline']['events'];

              if (timelineEvents != null && timelineEvents.length > 0) {
                final messageEvent = timelineEvents.singleWhere(
                  (element) => element['type'] == EventTypes.MESSAGE,
                  orElse: () => null,
                );

                if (messageEvent != null) {
                  final String messageSender = messageEvent['sender'];
                  final formattedSender =
                      messageSender.replaceFirst('@', '').split(':')[0];
                  showMessageNotification(
                    messageHash: Random.secure().nextInt(20000),
                    body: '$formattedSender sent you a new message.',
                    pluginInstance: pluginInstance,
                  );
                }
              }
            });

            final newLastSince = data['next_batch'];
            backgroundCache.put(Cache.lastSinceKey, newLastSince);

            print(
              "[AndroidAlarmService] New Last Since $newLastSince",
            );
          } catch (error) {
            print('[AndroidAlarmService] sync failed $error');
          }
        });
      }
    }
  } catch (error) {
    print('[BackgroundSync Service] failed $error');
  }
}
