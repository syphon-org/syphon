import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:Tether/global/libs/hive/index.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import 'package:Tether/global/libs/matrix/rooms.dart';
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
    print('[BackgroundSync] Starting Background Sync Service');

    final backgroundServiceHive = await initHiveBackgroundServiceUnsafe();
    await backgroundServiceHive.put('accessToken', accessToken);

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
 *  () {
        try {
          backgroundSync(
            protocol: protocol,
            homeserver: homeserver,
            accessToken: accessToken,
            lastSince: lastSince,
          );
        } catch (err) {
          print(err);
        }
      },
 */

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
    const String SINCE_CACHE_KEY = 'lastSince';
    const int syncInterval = 2;
    const int secondsTimeout = 60;
    final int isolateId = Isolate.current.hashCode;

    String protocol = 'https://';
    String homeserver = 'matrix.org';
    String accessToken;

    Box backgroundCache;

    if (Platform.isIOS || Platform.isAndroid) {
      // Init storage location
      var storageLocation;
      try {
        storageLocation = await getApplicationDocumentsDirectory();
      } catch (error) {
        print('[initHiveStorage] storage location failure - $error');
      }

      // Init hive cache + adapters
      Hive.init(storageLocation.path);
      backgroundCache = await Hive.openBox(Cache.backgroundServiceBox);
      accessToken = backgroundCache.get('accessToken');
    }

    // TODO: remove onSelect handler
    FlutterLocalNotificationsPlugin pluginInstance = await initNotifications();

    showBackgroundServiceNotification(
      notificationId: tether_service_id,
      debugContent: DateFormat('E h:mm:ss a').format(DateTime.now()),
      pluginInstance: pluginInstance,
    );

    for (int i = 0; i < secondsTimeout; i++) {
      if (i % syncInterval == 0) {
        Timer(Duration(seconds: i), () async {
          final DateTime now = DateTime.now();

          // Check isolate id and maybe see if a new one is created
          print(
            "[AndroidAlarmService] Running Fetch Sync $i timestamp=$now isolate=$isolateId",
          );

          // TODO: fetchSync here and check for new messages,
          // TODO: save an alternate lastSince for the background service only
          final data = await fetchSyncIsolate(
            protocol: protocol,
            homeserver: homeserver,
            accessToken: accessToken,
            since: backgroundCache.get(SINCE_CACHE_KEY),
          );

          final String lastSince = data['next_batch'];
          final Map<String, dynamic> rawRooms = data['rooms']['join'];

          backgroundCache.put(SINCE_CACHE_KEY, lastSince);

          print(
            "[AndroidAlarmService] New Last Since ${data['next_batch']}",
          );

          print(
            "[AndroidAlarmService] Room Data $rawRooms}",
          );

          /**
         * Check last since and see if any new messages arrived in the payload
         * No need to update the hive store for now, just do not save the lastSince
         * to the store and the next foreground fetchSync will update the state
         */

          if (false) {
            showMessageNotification(
              messageHash: Random.secure().nextInt(20000),
              pluginInstance: pluginInstance,
            );
          }
        });
      }
    }
  } catch (error) {
    print('[BackgroundSync Service] failed $error');
  }
}

/**
 * Fetch Sync Isolate
 * includes all necessary dependencies to operate
 * independent of the redux store or the main application
 * thread
 */

Future<dynamic> fetchSyncIsolate({
  String protocol,
  String homeserver,
  String accessToken,
  String since,
}) async {
  final request = buildSyncRequest(
    protocol: protocol,
    homeserver: homeserver,
    accessToken: accessToken,
    fullState: false,
    since: since,
  );

  final response = await http.get(
    request['url'],
    headers: request['headers'],
  );

  return await json.decode(response.body);
}
