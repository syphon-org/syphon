import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/crypto/sessions/service/service.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/privacy-settings/actions.dart';
import 'package:syphon/store/settings/privacy-settings/storage.dart';

// TODO: only used for notifications currently
// TODO: will be used for background sync eventually
ThunkAction<AppState> startKeyBackupService() {
  return (Store<AppState> store) async {
    await KeyBackupService.init();

    final password = await loadBackupPassword();

    if (password.isEmpty) {
      return store.dispatch(addAlert(
        origin: 'startKeyBackupService',
        message:
            'Password was not found for scheduled key backup, check your backup in settings',
      ));
    }

    final location =
        store.state.settingsStore.storageSettings.keyBackupLocation;
    final schedule =
        store.state.settingsStore.privacySettings.keyBackupInterval;
    final deviceKeys = store.state.cryptoStore.deviceKeys;
    final messageSessions = store.state.cryptoStore.messageSessionsInbound;
    final lastBackupMillis =
        store.state.settingsStore.privacySettings.lastBackupMillis;

    await KeyBackupService.start(
        path: location,
        password: password,
        frequency: schedule,
        lastBackupMillis: lastBackupMillis,
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
