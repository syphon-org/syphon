import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/domain/alerts/actions.dart';
import 'package:syphon/domain/crypto/sessions/service/service.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/settings/privacy-settings/actions.dart';
import 'package:syphon/domain/settings/privacy-settings/storage.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

ThunkAction<AppState> startKeyBackupService() {
  return (Store<AppState> store) async {
    final frequency = store.state.settingsStore.privacySettings.keyBackupInterval;

    if (frequency == Duration.zero) {
      console.info('[KeyBackupService] disabled - no schedule frequency');
      return Future.value();
    } else {
      console.info('[KeyBackupService] initing');
      await KeyBackupService.init();
    }

    final password = await loadBackupPassword();

    if (password.isEmpty) {
      return store.dispatch(addAlert(
        origin: 'startKeyBackupService',
        message: 'Password was not found for scheduled key backup, check your backup in settings',
      ));
    }

    final lastBackupMillis = store.state.settingsStore.privacySettings.lastBackupMillis;

    final lastBackup = DateTime.fromMillisecondsSinceEpoch(
      int.parse(lastBackupMillis),
    );

    // add the frequency to the last backup time
    final nextBackup = lastBackup.add(frequency);
    // find the amount of time that has passed since the last backup
    final nextBackupDelta = nextBackup.difference(DateTime.now());

    if (DEBUG_MODE && DEBUG_PAYLOADS_MODE) {
      console.jsonDebug({
        'frequency': frequency.toString(),
        'lastBackup': lastBackup.toIso8601String(),
        'nextBackup': nextBackup.toIso8601String(),
        'nextBackupDelta': nextBackupDelta.toString(),
        'nextBackupDeltaNegative': nextBackupDelta.isNegative,
      });
    }

    // if enough time has passed, start the job immediately
    if (nextBackupDelta.isNegative) {
      final location = store.state.settingsStore.storageSettings.keyBackupLocation;
      final deviceKeys = store.state.cryptoStore.deviceKeys;
      final messageSessions = store.state.cryptoStore.messageSessionsInbound;

      await KeyBackupService.start(
          path: location,
          password: password,
          deviceKeys: deviceKeys,
          messageSessions: messageSessions,
          onCompleted: () {
            store.dispatch(SetLastBackupMillis(
              timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
            ));
          });

      // TODO: notify the user that a backup is running
      // showBackgroundServiceNotification(
      //   notificationId: KeyBackupService.service_id,
      //   pluginInstance: globalNotificationPluginInstance!,
      // );
    }
  };
}

ThunkAction<AppState> stopKeyBackupService() {
  return (Store<AppState> store) async {
    KeyBackupService.stop();
    dismissAllNotifications(
      pluginInstance: globalNotificationPluginInstance,
    );
  };
}

ThunkAction<AppState> resetKeyBackupService() {
  return (Store<AppState> store) async {
    // Reset notification background thread
    await store.dispatch(stopKeyBackupService());
    await store.dispatch(startKeyBackupService());
  };
}
