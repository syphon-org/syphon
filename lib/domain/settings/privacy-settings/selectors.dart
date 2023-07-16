import 'dart:io';

import 'package:syphon/domain/index.dart';
import 'package:syphon/global/values.dart';

String selectKeyBackupSchedule(AppState state) {
  final schedule = state.settingsStore.privacySettings.keyBackupInterval;

  if (schedule.inHours == 1) {
    return 'Every hour';
  } else if (schedule.inMinutes == 15) {
    return 'Every 15 minutes';
  } else if (schedule.inHours == 6) {
    return 'Every 6 hours';
  } else if (schedule.inHours == 12) {
    return 'Every 12 hours';
  } else if (schedule.inDays == 1) {
    return 'Every Day';
  } else if (schedule.inDays == 7) {
    return 'Every Week';
  } else if (schedule.inDays == 29) {
    return 'Every Month';
  } else {
    return 'Manual Only';
  }
}

String selectKeyBackupLocation(AppState state) {
  final location = state.settingsStore.storageSettings.keyBackupLocation;

  if (location.isNotEmpty) {
    return location;
  }

  if (Platform.isAndroid) {
    return Values.ANDROID_DEFAULT_DIRECTORY;
  }

  return 'System Default';
}
