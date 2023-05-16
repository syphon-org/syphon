import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:syphon/domain/crypto/keys/models.dart';
import 'package:syphon/domain/crypto/sessions/model.dart';
import 'package:syphon/domain/crypto/sessions/service/functions.dart';
import 'package:syphon/global/print.dart';
import 'package:workmanager/workmanager.dart';

void callback() {
  Workmanager().executeTask((task, inputData) async {
    log.release(
      'Native called background task: $task',
    );

    final data = inputData ?? {};
    final directory = data['directory'];
    final password = data['password'];
    final deviceKeys = Map<String, Map<String, DeviceKey>>.from(
      jsonDecode(data['deviceKeys']),
    );

    final messageSessions = Map<String, Map<String, List<MessageSession>>>.from(
      jsonDecode(data['messageSessions']),
    );

    try {
      await backupSessionKeys(
        directory: directory,
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

  static Future start({
    required String path,
    required String password,
    required Map<String, Map<String, DeviceKey>> deviceKeys,
    required Map<String, Map<String, List<MessageSession>>> messageSessions,
    required Function onCompleted,
  }) async {
    final directory = await resolveBackupDirectory(path: path);
    final completed = await compute(backupSessionKeysThreaded, {
      'directory': directory,
      'password': password,
      'deviceKeys': deviceKeys,
      'messageSessions': messageSessions,
    });

    if (completed) {
      log.info('[KeyBackupService] completed backup successfully!!');
      return onCompleted();
    } else {
      log.error('[KeyBackupService] completed backup successfully!!');
    }

    // TODO: does not work on iOS, must work on both android and iOS
    // Workmanager().registerOneOffTask(
    //   service_title, service_title, // Ignored on iOS
    //   initialDelay: Duration.zero,
    //   constraints: Constraints(
    //     networkType: NetworkType.not_required,
    //     requiresBatteryNotLow: true,
    //   ),
    //   inputData: {
    //     'directory': directory,
    //     'password': password,
    //     'deviceKeys': jsonEncode(deviceKeys),
    //     'messageSessions': jsonEncode(messageSessions),
    //   },
    // );
  }

  static Future stop() async {
    try {
      await Workmanager().cancelAll();
    } catch (error) {
      log.error('[KeyBackupService] $error');
    }
  }
}
