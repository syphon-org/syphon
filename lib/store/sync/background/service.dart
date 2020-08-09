// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:android_alarm_manager/android_alarm_manager.dart';

// Project imports:
import 'package:syphon/global/libs/hive/index.dart';

// Dart imports:
import 'dart:math';

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/selectors.dart';

/**
 * Background Sync Service (Android Only)
 * static class for managing service through app lifecycle
 */
class BackgroundSync {
  static const service_id = 254;
  static const serviceTimeout = 55; // seconds

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

    await backgroundServiceHive.put(Cache.protocol, protocol);
    await backgroundServiceHive.put(Cache.homeserver, homeserver);
    await backgroundServiceHive.put(Cache.accessTokenKey, accessToken);
    await backgroundServiceHive.put(Cache.lastSinceKey, lastSince);
    await backgroundServiceHive.put(Cache.currentUser, currentUser);

    await AndroidAlarmManager.periodic(
      Duration(seconds: serviceTimeout),
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

/** 
 *  Save Full Sync
 * 
 *  https://github.com/hivedb/hive/issues/122
 */
FutureOr<void> saveSyncIsolate(dynamic params) async {
  // print('[saveSyncIsolate] ${Isolate.current.hashCode} ${params['location']}');

  Hive.init(params['location']);

  Box syncBox = await Hive.openBox(Cache.syncKeyUNSAFE);

  // final encryptionKey = await unlockEncryptionKey();

  // final syncBox = await Hive.openBox(
  //   Cache.syncKey,
  //   encryptionCipher: HiveAesCipher(encryptionKey),
  //   compactionStrategy: (entries, deletedEntries) => deletedEntries > 1,
  // );

  await syncBox.put(Cache.syncData, params['sync']);
  await syncBox.close();
}

/** 
 *  Save Full Sync
 */
FutureOr<dynamic> loadSyncIsolate(dynamic params) async {
  Hive.init(params['location']);

  Box syncBox = await Hive.openBox(Cache.syncKeyUNSAFE);

  final syncData = await syncBox.get(Cache.syncData);
  await syncBox.close();

  return syncData;
}

/** 
 *  Save Full Sync
 */
FutureOr<dynamic> syncLoop({
  Box cache,
  FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  try {
    // Check isolate id and maybe see if a new one is created
    final String protocol = cache.get(
      Cache.protocol,
    );

    final String homeserver = cache.get(
      Cache.homeserver,
    );

    final String accessToken = cache.get(
      Cache.accessTokenKey,
    );

    final String lastSince = cache.get(
      Cache.lastSinceKey,
    );

    final String currentUser = cache.get(
      Cache.currentUser,
    );

    if (accessToken == null || lastSince == null) {
      return;
    }

    /**
             * Check last since and see if any new messages arrived in the payload
             * No need to update the hive store for now, just do not save the lastSince
             * to the store and the next foreground fetchSync will update the state
             */
    final data = await MatrixApi.sync(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      since: lastSince,
      timeout: 10000,
    );

    final lastSinceNew = data['next_batch'];
    final Map<String, dynamic> rawRooms = data['rooms']['join'];

    try {
      await cache.put(Cache.lastSinceKey, lastSinceNew);

      /**
              *TODO: Need to handle group / bigger room chats differently than direct chats
              */
      rawRooms.forEach((roomId, json) {
        print('Sync Payload $json');
        // Filter through parsers
        final room = Room().fromSync(json: json, lastSince: lastSinceNew);

        if (room.messages.length == 1) {
          final String messageSender = room.messages[0].sender;
          final formattedSender = trimAlias(messageSender);

          if (!formattedSender.contains(currentUser)) {
            if (room.direct) {
              return showMessageNotification(
                messageHash: Random.secure().nextInt(20000),
                body: '$formattedSender sent a new message.',
                pluginInstance: pluginInstance,
              );
            }

            if (room.invite) {
              return showMessageNotification(
                messageHash: Random.secure().nextInt(20000),
                body: '$formattedSender invited you to chat',
                pluginInstance: pluginInstance,
              );
            }

            return showMessageNotification(
              messageHash: Random.secure().nextInt(20000),
              body: '$formattedSender sent a new message',
              pluginInstance: pluginInstance,
            );
          }
        }
      });
    } catch (error) {
      print('[notificationSyncIsolate] to cache new lastSince');
    }
  } catch (error) {
    print('[notificationSyncIsolate] sync failed $error');
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
void notificationSyncIsolate() async {
  try {
    // Init storage location
    var storageLocation;
    try {
      storageLocation = await getApplicationDocumentsDirectory();
    } catch (error) {
      print('[notificationSyncIsolate] storage location failure - $error');
    }

    // Init hive cache + adapters
    Hive.init(storageLocation.path);
    Box backgroundCache = await Hive.openBox(Cache.backgroundKeyUNSAFE);

    // Init notifiations for background service and new messages/events
    FlutterLocalNotificationsPlugin pluginInstance = await initNotifications();

    showBackgroundServiceNotification(
      notificationId: BackgroundSync.service_id,
      pluginInstance: pluginInstance,
    );

    /**
     *  TODO: explain this a bit
     */

    final cutoff = DateTime.now().add(
      Duration(seconds: BackgroundSync.serviceTimeout),
    );

    while (DateTime.now().isBefore(cutoff)) {
      await Future.delayed(Duration(seconds: 2));
      print('[notificationSyncIsolate] syncing');
      await syncLoop(
        cache: backgroundCache,
        pluginInstance: pluginInstance,
      );
      print('[notificationSyncIsolate] sync completed - waiting');
    }
  } catch (error) {
    print('[notificationSyncIsolate] init failed $error');
  }
}
