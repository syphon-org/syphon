import 'dart:async';
import 'dart:isolate';
import 'dart:math';
import 'package:syphon/global/libs/hive/index.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/sync/background/service.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/selectors.dart';
import 'package:hive/hive.dart';

import 'package:syphon/global/notifications.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/** 
 *  Save Full Sync
 * 
 *  https://github.com/hivedb/hive/issues/122
 */
FutureOr<void> saveSyncIsolate(dynamic params) async {
  print('[saveSyncIsolate] ${Isolate.current.hashCode} ${params['location']}');

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

  print('[saveSyncIsolate] successful save');
}

/** 
 *  Save Full Sync
 */
FutureOr<dynamic> loadSyncIsolate(dynamic params) async {
  print('[loadSyncIsolate] ${Isolate.current.hashCode}');

  Hive.init(params['location']);

  Box syncBox = await Hive.openBox(Cache.syncKeyUNSAFE);

  final syncData = await syncBox.get(Cache.syncData);
  await syncBox.close();

  print('[loadSyncIsolate] successful load');
  return syncData;
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
      print('[initHiveStorage] storage location failure - $error');
    }

    // Init hive cache + adapters
    Hive.init(storageLocation.path);
    Box backgroundCache = await Hive.openBox(Cache.backgroundKeyUNSAFE);

    // Init notifiations for background service and new messages/events
    FlutterLocalNotificationsPlugin pluginInstance = await initNotifications();
    showBackgroundServiceNotification(
      notificationId: BackgroundSync.service_id,
      debugContent: DateFormat('E h:mm:ss a').format(DateTime.now()),
      pluginInstance: pluginInstance,
    );

    /**
     *  TODO: explain this a bit
     */
    const service_interval = BackgroundSync.service_interval;
    const sync_interval = SyncStore.default_interval;

    for (int i = 0; i < service_interval; i++) {
      if (i % sync_interval == 0) {
        Timer(Duration(seconds: i), () async {
          try {
            // Check isolate id and maybe see if a new one is created
            print(
              "[notificationSyncIsolate] sync started (${Isolate.current.hashCode}) ($i) timestamp=${DateTime.now()}",
            );

            final String protocol = backgroundCache.get(
              Cache.protocol,
            );

            final String homeserver = backgroundCache.get(
              Cache.homeserver,
            );

            final String accessToken = backgroundCache.get(
              Cache.accessTokenKey,
            );

            final String lastSince = backgroundCache.get(
              Cache.lastSinceKey,
            );

            if (accessToken == null || lastSince == null) {
              print(
                '[notificationSyncIsolate] sync failed | ${accessToken == null ? 'accessToken' : 'lastSince'} must be present to sync',
              );
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
            );

            final newLastSince = data['next_batch'];
            final Map<String, dynamic> rawRooms = data['rooms']['join'];

            backgroundCache.put(Cache.lastSinceKey, newLastSince);
            print(
              "[notificationSyncIsolate] sync updated since $newLastSince",
            );

            /**
              *TODO: Need to handle group / bigger room chats differently than direct chats
              */
            rawRooms.forEach((roomId, json) {
              // Filter through parsers
              final room = Room().fromSync(
                json: json,
                lastSince: newLastSince,
              );

              if (room.messages.length == 1) {
                final String messageSender = room.messages[0].sender;
                final formattedSender = formatShortname(messageSender);

                showMessageNotification(
                  messageHash: Random.secure().nextInt(20000),
                  body: '$formattedSender sent a new message.',
                  pluginInstance: pluginInstance,
                );
              }
            });

            print("[notificationSyncIsolate] sync completed");
          } catch (error) {
            print('[notificationSyncIsolate] sync failed $error');
          }
        });
      }
    }
  } catch (error) {
    print('[notificationSyncIsolate] init failed $error');
  }
}
