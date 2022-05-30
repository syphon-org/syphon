import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/crypto/sessions/service/service.dart';
import 'package:syphon/store/index.dart';

// TODO: only used for notifications currently
// TODO: will be used for background sync eventually
ThunkAction<AppState> startKeyBackupService() {
  return (Store<AppState> store) async {
    await KeyBackupService.init();

    final location =
        store.state.settingsStore.storageSettings.keyBackupLocation;
    final schedule =
        store.state.settingsStore.privacySettings.keyBackupInterval;
    final deviceKeys = store.state.cryptoStore.deviceKeys;
    final messageSessions = store.state.cryptoStore.messageSessionsInbound;

    final lastBackup = DateTime.fromMillisecondsSinceEpoch(
      int.parse(store.state.settingsStore.privacySettings.lastBackupMillis),
    );
    final nextBackup = lastBackup.add(schedule);

    // find the amount of time that has passed since the last backup
    final lastBackupDelta = lastBackup.difference(DateTime.now());

    // subtract the duration until the nextBackup based on the time above
    final nextBackupDelta =
        nextBackup.subtract(lastBackupDelta).difference(lastBackup);

    // TODO: debug only
    log.json({
      'lastBackup': lastBackup,
      'nextBackup': nextBackup,
      'lastBackupDelta': lastBackupDelta,
      'nextBackupDelta': nextBackupDelta,
    });

    await KeyBackupService.start(
      location: location,
      password: '',
      schedule: nextBackupDelta,
      deviceKeys: deviceKeys,
      messageSessions: messageSessions,
    );

    // TODO: notify the user that a backup is running
    // showBackgroundServiceNotification(
    //   notificationId: KeyBackupService.service_id,
    //   pluginInstance: globalNotificationPluginInstance!,
    // );
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
