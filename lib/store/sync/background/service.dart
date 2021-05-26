// Dart imports:
import 'dart:math';
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

// Package imports:
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:syphon/global/algos.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/sync/background/parsers.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/user/selectors.dart';

/// Background Sync Service (Android Only)
/// static class for managing service through app lifecycle
class BackgroundSync {
  static const service_id = 255;
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

  static Future start({
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
      secureStorage.write(key: Cache.protocolKey, value: protocol),
      secureStorage.write(key: Cache.homeserverKey, value: homeserver),
      secureStorage.write(key: Cache.accessTokenKey, value: accessToken),
      secureStorage.write(key: Cache.lastSinceKey, value: lastSince),
      secureStorage.write(key: Cache.userIdKey, value: currentUser),
      secureStorage.write(key: Cache.roomNamesKey, value: jsonEncode(roomNames))
    ]);

    await AndroidAlarmManager.periodic(
      Duration(seconds: serviceTimeout),
      service_id,
      notificationSyncIsolate,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  static Future stop() async {
    try {
      await AndroidAlarmManager.cancel(service_id);
    } catch (error) {
      debugPrint('[BackgroundSync] $error');
    }
  }
}

///
/// Background Sync Job (Android Only)
///
/// Fetches data from matrix in background and displays
/// notifications without needing google play services
///
/// NOTE: https://github.com/flutter/flutter/issues/32164
///
Future notificationSyncIsolate() async {
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

      await backgroundSyncLoop(
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
Future backgroundSyncLoop({
  required Map params,
  FlutterLocalNotificationsPlugin? pluginInstance,
}) async {
  try {
    print('[backgroundSyncLoop] starting sync loop');
    final protocol = params['protocol'];
    final homeserver = params['homeserver'];
    final accessToken = params['accessToken'];
    final lastSince = params['lastSince'];
    final currentUserId = params['userId'] ?? params['currentUser'];

    final roomNames = Map<String, String>.from(
      params['roomNames'] ?? {},
    );

    if (accessToken == null || lastSince == null) {
      return;
    }

    // Try to pull new lastSince if available
    final currentLastSince = await loadLastSince(fallback: lastSince);

    /**
     * Check last since and see if any new messages arrived in the payload
     * do not save the lastSince to the store and 
     * the next foreground fetchSync will update the state
     */
    final data = await MatrixApi.sync(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      since: currentLastSince,
      timeout: 10000,
    );

    // Parse sync response
    final nextLastSince = data['next_batch'];

    // Save new 'since' value for the next sync
    saveLastSince(lastSince: nextLastSince);

    // Filter each room through the parser
    final Map<String, dynamic> rooms = data['rooms']['join'];

    // Run all the rooms at once
    await Future.wait(rooms.entries.map((roomJson) async {
      final roomId = roomJson.key;
      final roomData = roomJson.value;

      final room = Room(id: roomId).fromSync(
        json: roomData,
        lastSince: nextLastSince,
      );

      if (room.messagesNew.isEmpty) {
        return;
      }

      // Make sure the room name exists in the cache
      if (!roomNames.containsKey(room.id)) {
        try {
          final roomNameList = await MatrixApi.fetchRoomName(
            protocol: protocol,
            homeserver: homeserver,
            accessToken: accessToken,
            roomId: room.id.isEmpty ? roomId : room.id,
          );

          final roomAlias = roomNameList[roomNameList.length - 1];
          final roomName =
              roomAlias.replaceAll('#', '').replaceAll(r'\:.*', '');

          roomNames[room.id] = roomName;
          saveRoomNames(roomNames: roomNames);
        } catch (error) {
          print(
            '[backgroundSyncLoop] failed to fetch & parse room name ${room.id}',
          );
        }
      }

      // Run all the room messages at once once room name is conirmed
      Future.wait(room.messagesNew.map((message) async {
        final body = await parseMessageNotification(
          room: room,
          message: message,
          roomNames: roomNames,
          currentUserId: currentUserId,
          protocol: protocol,
          homeserver: homeserver,
        );

        if (body.isEmpty) return Future.value();

        final int messageTrxId = Random.secure().nextInt(1 << 31);

        showMessageNotification(
          messageHash: messageTrxId,
          body: body,
          pluginInstance: pluginInstance!,
        );
      }));
    }));
  } catch (error) {
    print('[backgroundSyncLoop] $error');
  }
}
