import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/domain/index.dart';
import 'package:syphon/domain/sync/service/service.dart';

ThunkAction<AppState> startSyncService() {
  return (Store<AppState> store) async {
    await SyncService.init();

    final Map<String, String?> roomNames = store.state.roomStore.rooms.map(
      (roomId, room) => MapEntry(roomId, room.name),
    );

    await SyncService.start(
      roomNames: roomNames,
      protocol: store.state.authStore.protocol,
      lastSince: store.state.syncStore.lastSince,
      currentUser: store.state.authStore.currentUser,
      settings: store.state.settingsStore.notificationSettings,
      proxySettings: store.state.settingsStore.proxySettings,
    );

    showBackgroundServiceNotification(
      notificationId: SyncService.service_id,
      pluginInstance: globalNotificationPluginInstance!,
    );
  };
}

ThunkAction<AppState> stopSyncService() {
  return (Store<AppState> store) async {
    SyncService.stop();
    dismissAllNotifications(
      pluginInstance: globalNotificationPluginInstance,
    );
  };
}

ThunkAction<AppState> resetSyncService() {
  return (Store<AppState> store) async {
    // Reset notification background thread
    await store.dispatch(stopSyncService());
    await store.dispatch(startSyncService());
  };
}
