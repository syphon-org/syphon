import 'dart:async';
import 'dart:convert';

import 'package:syphon/global/print.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/service/functions.dart';
import 'package:syphon/store/crypto/sessions/model.dart';
import 'package:workmanager/workmanager.dart';

void callback() {
  Workmanager().executeTask((task, inputData) async {
    log.release(
      'Native called background task: $task',
    );

    final data = inputData ?? {};
    final location = data['location'];
    final password = data['password'];
    final deviceKeys = Map<String, Map<String, DeviceKey>>.from(
      jsonDecode(data['deviceKeys']),
    );

    final messageSessions = Map<String, Map<String, List<MessageSession>>>.from(
      jsonDecode(data['messageSessions']),
    );

    // TODO: debug ONLY
    log.json({
      'location': location,
      'password': password,
      'deviceKeys': deviceKeys,
      'messageSessions': messageSessions,
    });

    try {
      await exportSessionKeysThreaded(
        location: location,
        password: password,
        deviceKeys: deviceKeys,
        messageSessions: messageSessions,
      );
    } catch (error) {
      log.error(error.toString());
    }

    return Future.value(true);
  });
}

/// Key Backup Service
///
/// Responsible for backing up session keys
/// on a schedule
///
class KeyBackupService {
  static const service_id = 156;
  static const serviceTimeout = 55; // seconds
  static const service_title = 'KeyBackupService';

  static Future start({
    required String location,
    required String password,
    required Map<String, Map<String, DeviceKey>> deviceKeys,
    required Map<String, Map<String, List<MessageSession>>> messageSessions,
    required Duration schedule,
  }) async {
    log.info('[KeyBackupService] starting');

    if (schedule == Duration.zero) return;

    Workmanager().registerOneOffTask(
      service_title, service_title, // Ignored on iOS
      initialDelay: schedule,
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
      ),
      inputData: {
        'location': location,
        'password': password,
        'deviceKeys': jsonEncode(deviceKeys),
        'messageSessions': jsonEncode(messageSessions),
      },
    );
  }

  static Future<bool> init() async {
    try {
      await Workmanager().initialize(
        callback, // The top level function, aka callbackDispatcher
        isInDebugMode: false, // prints notification on run
      );
      return true;
    } catch (error) {
      log.error('[KeyBackupService.init] $error');
      return false;
    }
  }

  static Future stop() async {
    try {
      await Workmanager().cancelAll();
    } catch (error) {
      log.error('[KeyBackupService] $error');
    }
  }
}
