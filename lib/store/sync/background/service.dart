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
import 'package:syphon/cache/index.dart';

// Dart imports:
import 'dart:math';

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/user/selectors.dart';

/// Background Sync Service (Android Only)
/// static class for managing service through app lifecycle
class BackgroundSync {
  static const service_id = 254;
  static const serviceTimeout = 55; // seconds

  static Isolate? backgroundIsolate;

  static Future<bool> init() async {
    try {
      return await AndroidAlarmManager.initialize();
    } catch (error) {
      debugPrint('[BackgroundSync.init] $error');
      return false;
    }
  }

  static void start({
    String? protocol,
    String? homeserver,
    String? accessToken,
    String? lastSince,
    String? currentUser,
    Map<String, String?>? roomNames,
  }) async {
    // android only background sync
    if (!Platform.isAndroid) return;

    final secureStorage = FlutterSecureStorage();

    await Future.wait([
      secureStorage.write(
        key: Cache.protocolKey,
        value: protocol,
      ),
      secureStorage.write(
        key: Cache.homeserverKey,
        value: homeserver,
      ),
      secureStorage.write(
        key: Cache.accessTokenKey,
        value: accessToken,
      ),
      secureStorage.write(
        key: Cache.lastSinceKey,
        value: lastSince,
      ),
      secureStorage.write(
        key: Cache.userIdKey,
        value: currentUser,
      ),
      secureStorage.write(
        key: Cache.roomNamesKey,
        value: jsonEncode(roomNames),
      )
    ]);

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
      debugPrint('[BackgroundSync] $error');
    }
  }
}

/// Background Sync Job (Android Only)
/// 
/// Fetches data from matrix in background and displays
/// notifications without needing google play services
/// 
/// NOTE: https://github.com/flutter/flutter/issues/32164
void notificationSyncIsolate() async {
  try {
    String? protocol;
    String? homeserver;
    String? accessToken;
    String? lastSince;
    String? userId;
    Map<String, dynamic>? roomNames;

    try {
      final secureStorage = FlutterSecureStorage();

      userId = await secureStorage.read(key: Cache.userIdKey);
      protocol = await secureStorage.read(key: Cache.protocolKey);
      lastSince = await secureStorage.read(key: Cache.lastSinceKey);
      homeserver = await secureStorage.read(key: Cache.homeserverKey);
      accessToken = await secureStorage.read(key: Cache.accessTokenKey);
      final roomNamesData = await secureStorage.read(key: Cache.roomNamesKey);

      roomNames = jsonDecode(roomNamesData!);
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    // Init notifiations for background service and new messages/events
    final pluginInstance = (await initNotifications())!;

    showBackgroundServiceNotification(
      notificationId: BackgroundSync.service_id,
      pluginInstance: pluginInstance,
    );

    final cutoff = DateTime.now().add(
      Duration(seconds: BackgroundSync.serviceTimeout),
    );

    print('[notificationSyncIsolate] enabled background sync');

    while (DateTime.now().isBefore(cutoff)) {
      await Future.delayed(Duration(seconds: 2));

      await syncLoop(
        pluginInstance: pluginInstance,
        params: {
          'protocol': protocol,
          'homeserver': homeserver,
          'accessToken': accessToken,
          'lastSince': lastSince,
          'userId': userId,
          'roomNames': roomNames,
        },
      );
    }
  } catch (error) {
    print('[notificationSyncIsolate] $error');
  }
}

///  Save Full Sync
Future<dynamic> syncLoop({
  required Map params,
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  try {
    final protocol = params['protocol'];
    final homeserver = params['homeserver'];
    final accessToken = params['accessToken'];
    final lastSince = params['lastSince'];
    final userId = params['userId'] ?? params['currentUser'];
    final Map<String, dynamic>? roomNames = params['roomNames'];

    if (accessToken == null || lastSince == null) {
      return;
    }

    var lastSinceNew;

    // Try to pull new lastSince if available
    try {
      final secureStorage = FlutterSecureStorage();

      lastSinceNew = await secureStorage.read(
        key: Cache.lastSinceKey,
      );
    } catch (error) {
      print('[syncLoop] $error');
    }

    /**
     * Check last since and see if any new messages arrived in the payload
     * do not save the lastSince to the store and 
     * the next foreground fetchSync will update the state
     */
    final data = await MatrixApi.sync(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      since: lastSinceNew ?? lastSince,
      timeout: 10000,
    );

    // Parse sync response
    lastSinceNew = data['next_batch'];
    final Map<String, dynamic> rawRooms = data['rooms']['join'];

    // Save new 'since' value for the next sync
    try {
      final secureStorage = FlutterSecureStorage();

      await secureStorage.write(key: Cache.lastSinceKey, value: lastSinceNew);
    } catch (error) {
      print('[syncLoop] $error');
    }

    // Filter each room through the parser
    rawRooms.forEach((roomId, json) {
      final room =
          Room(id: roomId).fromSync(json: json, lastSince: lastSinceNew);
      final messagesNew = room.messagesNew;

      if (messagesNew.length == 1) {
        final String? messageSender = messagesNew[0].sender;
        final String formattedSender = trimAlias(messageSender);

        if (!formattedSender.contains(userId)) {
          if (room.direct) {
            showMessageNotification(
              messageHash: Random.secure().nextInt(20000),
              body: '$formattedSender sent a new message.',
              pluginInstance: pluginInstance!,
            );
            return;
          }

          if (room.invite) {
            showMessageNotification(
              messageHash: Random.secure().nextInt(20000),
              body: '$formattedSender invited you to chat',
              pluginInstance: pluginInstance!,
            );
            return;
          }

          final roomName = roomNames![roomId];
          showMessageNotification(
            messageHash: Random.secure().nextInt(20000),
            body: '$formattedSender sent a new message in $roomName',
            pluginInstance: pluginInstance!,
          );
          return;
        }
      }
    });
  } catch (error) {
    print('[syncLoop] $error');
  }
}
