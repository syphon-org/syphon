import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/sync/background/parsers.dart';
import 'package:syphon/store/sync/background/storage.dart';
import 'package:syphon/store/sync/parsers.dart';
import 'package:syphon/store/user/model.dart';

/// Background Sync Service (Android Only)
/// static class for managing service through app lifecycle
class BackgroundSync {
  static const service_id = 255;
  static const serviceTimeout = 55; // seconds

  static Isolate? backgroundIsolate;

  static const notificationSettings = 'notificationSettings';
  static const notificationsUnchecked = 'notificationsUnchecked';

  static Future<bool> init() async {
    try {
      return await AndroidAlarmManager.initialize();
    } catch (error) {
      printError('[BackgroundSync.init] $error');
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
    NotificationSettings? settings,
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
      secureStorage.write(key: Cache.roomNamesKey, value: jsonEncode(roomNames)),
      secureStorage.write(key: notificationSettings, value: jsonEncode(settings))
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
      printError('[BackgroundSync] $error');
    }
  }
}

///
/// Foreground Sync Job (TESTING ONLY)
///
/// Fetches data from matrix in background and displays
/// notifications without needing google play services
///
/// NOTE: https://github.com/flutter/flutter/issues/32164
///
Future notificationSyncTEST() async {
  try {
    // Init notifiations for background service and new messages/events
    final pluginInstance = await initNotifications(
      onSelectNotification: (String? payload) {
        printDebug(
          '[onSelectNotification] TESTING PAYLOAD INSIDE BACKGROUND THREAD $payload',
        );
        return Future.value(true);
      },
    );
    String? protocol;
    String? homeserver;
    String? accessToken;
    String? lastSince;
    String? userId;

    try {
      final secureStorage = FlutterSecureStorage();
      userId = await secureStorage.read(key: Cache.userIdKey);
      protocol = await secureStorage.read(key: Cache.protocolKey);
      lastSince = await secureStorage.read(key: Cache.lastSinceKey);
      homeserver = await secureStorage.read(key: Cache.homeserverKey);
      accessToken = await secureStorage.read(key: Cache.accessTokenKey);
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    final Map<String, String> roomNames = await loadRoomNames();

    await backgroundSyncLoop(
      pluginInstance: pluginInstance!,
      params: {
        'protocol': protocol,
        'homeserver': homeserver,
        'accessToken': accessToken,
        'lastSince': lastSince,
        'userId': userId,
        'roomNames': roomNames,
      },
    );
  } catch (error) {
    printError('[notificationSyncTEST] $error');
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

    try {
      final secureStorage = FlutterSecureStorage();
      userId = await secureStorage.read(key: Cache.userIdKey);
      protocol = await secureStorage.read(key: Cache.protocolKey);
      lastSince = await secureStorage.read(key: Cache.lastSinceKey);
      homeserver = await secureStorage.read(key: Cache.homeserverKey);
      accessToken = await secureStorage.read(key: Cache.accessTokenKey);
    } catch (error) {
      print('[notificationSyncIsolate] $error');
    }

    final Map<String, String> roomNames = await loadRoomNames();

    // Init notifiations for background service and new messages/events
    final pluginInstance = await initNotifications(
      onSelectNotification: (String? payload) {
        printDebug(
          '[onSelectNotification] TESTING PAYLOAD INSIDE BACKGROUND THREAD $payload',
        );
        return Future.value(true);
      },
    );

    if (pluginInstance == null) {
      throw '[notificationSyncIsolate] failed to initialize plugin instance';
    }

    showBackgroundServiceNotification(
      notificationId: BackgroundSync.service_id,
      pluginInstance: pluginInstance,
    );

    final cutoff = DateTime.now().add(
      Duration(seconds: BackgroundSync.serviceTimeout),
    );

    while (DateTime.now().isBefore(cutoff)) {
      await Future.delayed(Duration(seconds: 2));

      // TODO: check for on the fly disabled notification services

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
  required FlutterLocalNotificationsPlugin pluginInstance,
}) async {
  try {
    final protocol = params['protocol'];
    final homeserver = params['homeserver'];
    final accessToken = params['accessToken'];
    final lastSince = params['lastSince'];
    final currentUserId = params['userId'];

    final roomNames = Map<String, String>.from(
      params['roomNames'] ?? {},
    );

    if (accessToken == null || lastSince == null) {
      return;
    }

    // Try to pull new lastSince if available
    final currentLastSince = await loadLastSince(fallback: lastSince);
    final settings = await loadNotificationSettings();

    // Prevents further updates within background service if
    // disabled mid AlarmManager cycle
    if (!settings.enabled) {
      return;
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
      since: currentLastSince,
      timeout: 10000,
    );

    // Parse sync response
    final nextLastSince = data['next_batch'];

    // Save new 'since' value for the next sync
    saveLastSince(lastSince: nextLastSince);

    // Filter each room through the parser
    final Map<String, dynamic> roomJson = data['rooms'] ?? {};

    if (roomJson.isEmpty) {
      return;
    }

    final Map<String, dynamic> joinedJson = roomJson['join'] ?? {};
    final Map<String, dynamic> invitesJson = roomJson['invite'] ?? {};

    final roomsJson = joinedJson..addAll(invitesJson);

    // Run all the rooms at once
    await Future.forEach(roomsJson.keys, (String roomId) async {
      final roomJson = roomsJson[roomId];

      // Don't parse room if there are no message events found
      final events = parseEvents(
        roomJson,
      );

      if (events.messages.isEmpty) {
        return;
      }

      final details = parseDetails(
        roomJson,
      );

      final room = Room(id: roomId).fromEvents(
        events: events,
        currentUser: User(userId: currentUserId),
        lastSince: lastSince,
        limited: details.limited,
        lastBatch: details.lastBatch,
        prevBatch: details.prevBatch,
      );

      final chatOptions = settings.notificationOptions;
      final hasOptions = chatOptions.containsKey(roomId);

      if (settings.toggleType == ToggleType.Disabled && !hasOptions) {
        return;
      }

      if (hasOptions) {
        final options = chatOptions[roomId]!;
        if (!options.enabled) {
          return;
        }

        if (options.muted) {
          final mutedTimeout = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(options.muteTimestamp),
          );

          // future timeout still has not been met
          if (mutedTimeout.isNegative) {
            return;
          }
        }
      }

      // Make sure the room name exists in the cache
      if (!roomNames.containsKey(roomId) || roomNames[roomId] == Values.EMPTY_CHAT) {
        try {
          final roomNameList = await MatrixApi.fetchRoomName(
            protocol: protocol,
            homeserver: homeserver,
            accessToken: accessToken,
            roomId: room.id.isEmpty ? roomId : room.id,
          );

          final roomAlias = roomNameList[roomNameList.length - 1];
          final roomName = roomAlias.replaceAll('#', '').replaceAll(r'\:.*', '');

          roomNames[room.id] = roomName;

          saveRoomNames(roomNames: roomNames);
        } catch (error) {
          // ignore: avoid_print
          print('[backgroundSyncLoop] failed to fetch & parse room name ${room.id}');
        }
      }

      final uncheckedMessages = await loadNotificationsUnchecked();

      ///
      /// Inbox Style Notifications Only
      ///
      if (settings.styleType == StyleType.Inbox) {
        for (final message in events.messages) {
          final messageBody = parseMessageNotification(
            room: room,
            message: message,
            roomNames: roomNames,
            currentUserId: currentUserId,
            protocol: protocol,
            homeserver: homeserver,
          );

          uncheckedMessages.addAll(
            {message.id ?? '0': messageBody},
          );
        }

        await saveNotificationsUnchecked(uncheckedMessages);

        var body = 'You have a new unread message';

        if (uncheckedMessages.keys.length > 1) {
          body = 'You have ${uncheckedMessages.keys.length} unread messages';
        }

        return showMessageNotification(
          body: body,
          title: 'New Messages',
          style: settings.styleType,
          pluginInstance: pluginInstance,
          uncheckedMessages: uncheckedMessages,
        );
      }

      // Run all the room messages at once once room name is confirmed
      await Future.wait(events.messages.map((message) async {
        final title = parseMessageTitle(
          room: room,
          message: message,
          roomNames: roomNames,
          currentUserId: currentUserId,
          protocol: protocol,
          homeserver: homeserver,
        );

        final body = parseMessageNotification(
          room: room,
          message: message,
          roomNames: roomNames,
          currentUserId: currentUserId,
          protocol: protocol,
          homeserver: homeserver,
        );

        if (body.isEmpty) return Future.value();

        await showMessageNotification(
          id: uncheckedMessages.isEmpty ? 0 : null,
          body: body,
          title: title,
          style: settings.styleType,
          pluginInstance: pluginInstance,
        );

        uncheckedMessages.addAll(
          {message.id ?? '0': body},
        );

        await saveNotificationsUnchecked(uncheckedMessages);
      }));
    });
  } catch (error) {
    print('[backgroundSyncLoop] $error');
  }
}
