import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/model.dart';
import 'package:syphon/store/crypto/sessions/service/functions.dart';
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

  static Future start({
    required String path,
    required String password,
    required Map<String, Map<String, DeviceKey>> deviceKeys,
    required Map<String, Map<String, List<MessageSession>>> messageSessions,
    required String lastBackupMillis,
    required Duration frequency,
    required Function onCompleted,
  }) async {
    if (frequency == Duration.zero) {
      log.info('[KeyBackupService] disabled - no schedule frequency');
      return Future.value();
    } else {
      log.info('[KeyBackupService] starting');
    }

    final lastBackup = DateTime.fromMillisecondsSinceEpoch(
      int.parse(lastBackupMillis),
    );

    // add the frequency to the last backup time
    final nextBackup = lastBackup.add(frequency);
    // find the amount of time that has passed since the last backup
    final nextBackupDelta = nextBackup.difference(DateTime.now());

    if (DEBUG_MODE) {
      log.json({
        'frequency': frequency.toString(),
        'lastBackup': lastBackup.toIso8601String(),
        'nextBackup': nextBackup.toIso8601String(),
        'nextBackupDelta': nextBackupDelta.toString(),
        'nextBackupDeltaNegative': nextBackupDelta.isNegative,
      });
    }

    // if more time has passed, start the backup process
    if (nextBackupDelta.isNegative) {
      final directory = await resolveBackupDirectory(path: path);
      final completed = await compute(backupSessionKeysThreaded, {
        'directory': directory,
        'password': password,
        'deviceKeys': deviceKeys,
        'messageSessions': messageSessions,
      });

      if (completed) {
        log.info('[KeyBackupService] completd backup successfully!!');
        return onCompleted();
      } else {
        log.error('[KeyBackupService] completd backup successfully!!');
      }
    }

    // TODO: cannot handle
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
