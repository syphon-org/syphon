import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/store/index.dart';
import 'package:syphon/store/settings/actions.dart';
import 'package:syphon/store/settings/notification-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/options/types.dart';

class MuteChatNotifications {
  final String roomId;
  final Duration duration;

  MuteChatNotifications({
    required this.roomId,
    required this.duration,
  });
}

// Eventually exist as its own store
class SetNotificationSettings {
  final NotificationSettings settings;
  SetNotificationSettings({required this.settings});
}

///
/// Mute Chat Notifications
///
/// Disable notifications for a certain period of time
/// for a specific chat
///
ThunkAction<AppState> muteChatNotifications({
  required String roomId,
  required int timestamp, // time until mute is irrelevant
}) {
  return (Store<AppState> store) async {
    final settings = store.state.settingsStore.notificationSettings;
    final options =
        Map<String, NotificationOptions>.from(settings.notificationOptions);

    options.putIfAbsent(roomId, () => NotificationOptions());

    options[roomId] = options[roomId]!.copyWith(
      muteTimestamp: timestamp,
      muted: true,
    );

    // notificationsSettings.chatOptions.update(roomId, (value) => );
    store.dispatch(SetNotificationSettings(
      settings: settings.copyWith(notificationOptions: options),
    ));
  };
}

///
/// Toggle Chat Notifications
///
/// Depending on the state of the allow list / block list
/// handling of notifications, this will either begin or end
/// notifications for a chat
///
ThunkAction<AppState> toggleChatNotifications({
  required String roomId,
  bool? enabled,
}) {
  return (Store<AppState> store) async {
    final settings = store.state.settingsStore.notificationSettings;
    final options =
        Map<String, NotificationOptions>.from(settings.notificationOptions);

    options.putIfAbsent(roomId, () => NotificationOptions());

    options[roomId] = options[roomId]!.copyWith(
      enabled: enabled ?? !options[roomId]!.enabled,
      muted: false,
    );

    store.dispatch(SetNotificationSettings(
      settings: settings.copyWith(notificationOptions: options),
    ));
  };
}

///
/// Update Toggle Type
///
/// Change the state of the allow list / block list
/// handling of notifications
///
ThunkAction<AppState> incrementToggleType() {
  return (Store<AppState> store) async {
    final settings = store.state.settingsStore.notificationSettings;

    final index = ToggleType.values.indexOf(settings.toggleType);
    final toggleType =
        ToggleType.values[(index + 1) % ToggleType.values.length];

    store.dispatch(SetNotificationSettings(
      settings: settings.copyWith(toggleType: toggleType),
    ));

    // Reset notification background thread
    await store.dispatch(stopNotifications());
    store.dispatch(startNotifications());
  };
}

///
/// Update Style Type
///
/// Change the style of notifications
/// ITEMIZED - One notification per message
/// INBOX - Grouped Together within one notification
/// GROUPED - Layered as the come in under one notification slot
///
ThunkAction<AppState> incrementStyleType() {
  return (Store<AppState> store) async {
    final settings = store.state.settingsStore.notificationSettings;

    final index = StyleType.values.indexOf(settings.styleType);
    final styleType = StyleType.values[(index + 1) % StyleType.values.length];

    store.dispatch(SetNotificationSettings(
      settings: settings.copyWith(styleType: styleType),
    ));

    // Reset notification background thread
    await store.dispatch(stopNotifications());
    store.dispatch(startNotifications());
  };
}
