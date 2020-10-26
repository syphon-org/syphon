// Dart imports:
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:syphon/global/cache/index.dart';

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
import 'package:syphon/store/auth/state.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/sync/state.dart';
import 'package:syphon/store/user/model.dart';
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
    Map<String, String> roomNames,
  }) async {
    // android only background sync
    if (!Platform.isAndroid) return;

    final box = await openHiveBackgroundUnsafe();

    await box.put(CacheSecure.protocol, protocol);
    await box.put(CacheSecure.homeserver, homeserver);
    await box.put(CacheSecure.accessTokenKey, accessToken);
    await box.put(CacheSecure.lastSinceKey, lastSince);
    await box.put(CacheSecure.currentUser, currentUser);
    await box.put(CacheSecure.roomNames, roomNames);

    await box.close();

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

  static void updateRooms({Map<String, String> roomNames}) async {
    final box = await openHiveBackgroundUnsafe();
    await box.put(CacheSecure.roomNames, roomNames);
    await box.close();
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
    var ivKey;
    var cryptKey;
    var storageLocation;
    var storageSecured;

    AuthStore authStore;
    SyncStore syncStore;

    try {
      storageSecured = FlutterSecureStorage();
      storageLocation = await getApplicationDocumentsDirectory();
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    try {
      // Pull encryption key and iv
      ivKey = await storageSecured.read(
        key: CacheSecure.ivKeyLocation,
      );

      cryptKey = await storageSecured.read(
        key: CacheSecure.cryptKeyLocation,
      );

      // Configure getters
      Box cacheMain = await Hive.openBox(CacheSecure.cacheKeyMain);
      final cryptor = AesCrypt(key: cryptKey, padding: PaddingAES.pkcs7);

      final authStoreEncrypted = cacheMain.get((AuthStore).toString());
      final syncStoreEncrypted = cacheMain.get((SyncStore).toString());

      final authStoreDecrypted =
          cryptor.ctr.decrypt(enc: authStoreEncrypted, iv: ivKey);
      final syncStoreDecrypted =
          cryptor.ctr.decrypt(enc: syncStoreEncrypted, iv: ivKey);

      authStore = jsonDecode(authStoreDecrypted);
      syncStore = jsonDecode(syncStoreDecrypted);
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    try {
      authStore.user.accessToken;
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    // Init hive cache + adapters
    Hive.init(storageLocation.path);
    Box backgroundCache = await Hive.openBox(CacheSecure.cacheKeyBackground);

    // Init notifiations for background service and new messages/events
    FlutterLocalNotificationsPlugin pluginInstance = await initNotifications();

    showBackgroundServiceNotification(
      notificationId: BackgroundSync.service_id,
      pluginInstance: pluginInstance,
    );

    final cutoff = DateTime.now().add(
      Duration(seconds: BackgroundSync.serviceTimeout),
    );

    while (DateTime.now().isBefore(cutoff)) {
      await Future.delayed(Duration(seconds: 2));
      print('[notificationSyncIsolate] syncing');

      await syncLoop(
        cache: backgroundCache,
        pluginInstance: pluginInstance,
        params: {
          'protocol': 'https://',
          'homeserver': (authStore.user ?? User()).homeserver,
          'accessToken': (authStore.user ?? User()).accessToken,
          'lastSince': syncStore.lastSince,
          'currentUser': (authStore.user ?? User()).userId,
        },
      );
      print('[notificationSyncIsolate] sync completed - waiting');
    }
  } catch (error) {
    print('[notificationSyncIsolate] init failed $error');
  }
}

/** 
 *  Save Full Sync
 */
FutureOr<dynamic> syncLoop({
  Box cache,
  FlutterLocalNotificationsPlugin pluginInstance,
  Map params,
}) async {
  try {
    final protocol = params['protocol'];
    final homeserver = params['homeserver'];
    final accessToken = params['accessToken'];
    final lastSince = params['lastSince'];
    final currentUser = params['currentUser'];

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
      await cache.put(CacheSecure.lastSinceKey, lastSinceNew);

      rawRooms.forEach((roomId, json) {
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
