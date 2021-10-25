import 'package:redux/redux.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/model.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/rooms/room/model.dart';

extension Chunked on String {
  String chunk(int size) {
    final items = split('');

    final chunks = <String>[];

    final int len = length;
    for (var i = 0; i < len; i += size) {
      final int range = i + size;
      chunks.add(items.sublist(i, range > len ? len : range).join());
    }

    return chunks.join(' ');
  }
}

String selectCurrentUserSessionKey(Store<AppState> store) {
  final currentDeviceId = store.state.authStore.user.deviceId;
  final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;

  if (deviceKeysOwned.containsKey(currentDeviceId)) {
    final currentDeviceKey = deviceKeysOwned[currentDeviceId];
    final fingerprintId = Keys.fingerprintId(deviceId: currentDeviceId);

    final String fingerprint =
        currentDeviceKey?.keys?[fingerprintId] ?? Values.UNKNOWN;

    return fingerprint.chunk(4);
  }

  return Values.UNKNOWN;
}

List<String> selectKeySessions(Store<AppState> store, String identityKey) {
  final keySessions = store.state.cryptoStore.keySessions;

  final keySessionsIdentity = keySessions[identityKey] ?? {};

  return keySessionsIdentity.values.toList();
}

List<DeviceKey> filterDevicesWithoutMessageSessions(
    Store<AppState> store, Room room) {
  final roomUserIds = room.userIds;
  final currentUser = store.state.authStore.user;
  final deviceKeys = store.state.cryptoStore.deviceKeys;
  final messageSessionsInbound = store.state.cryptoStore.inboundMessageSessions;
  final messageSessionsOutbound =
      store.state.cryptoStore.outboundMessageSessions;

  // get deviceKeys for every user present in the chat
  final List<DeviceKey> roomDeviceKeys = List.from(
    roomUserIds
        .map((userId) => (deviceKeys[userId] ?? {}).values)
        .expand((x) => x),
  );

  final devieKeysWithMessageSession = roomDeviceKeys.where(
    (deviceKey) {
      // the currentUser device will always create a message session for itself
      if (deviceKey.deviceId == currentUser.deviceId) return false;

      // has no outbound sessions, so every device in the chat is without a message session
      if (!messageSessionsOutbound.containsKey(room.id)) return true;

      // find the identityKey for the device
      final identityKeyId = Keys.identityKeyId(deviceId: deviceKey.deviceId);
      final identityKey = deviceKey.keys![identityKeyId];
      final hasMessageSession =
          !messageSessionsInbound.containsKey(identityKey);

      // key Session / Olm session already established
      if (!hasMessageSession) return true;

      return false;
    },
  );

  return devieKeysWithMessageSession.toList();
}

List<DeviceKey> filterDevicesWithKeySessions(Store<AppState> store, Room room) {
  final roomUserIds = room.userIds;
  final currentUser = store.state.authStore.user;
  final deviceKeys = store.state.cryptoStore.deviceKeys;
  final keySessions = store.state.cryptoStore.keySessions;

  // get deviceKeys for every user present in the chat
  final List<DeviceKey> roomDeviceKeys = List.from(
    roomUserIds
        .map((userId) => (deviceKeys[userId] ?? {}).values)
        .expand((x) => x),
  );

  final devieKeysWithSession = roomDeviceKeys.where(
    (deviceKey) {
      // the currentUser device doesn't need a key session for itself
      if (deviceKey.deviceId == currentUser.deviceId) return false;

      // find the identityKey for the device
      final identityKeyId = Keys.identityKeyId(deviceId: deviceKey.deviceId);
      final identityKey = deviceKey.keys![identityKeyId];

      // Key Session / Olm session already established
      if (keySessions.containsKey(identityKey)) return true;

      return false;
    },
  );

  return devieKeysWithSession.toList();
}

List<DeviceKey> filterDevicesWithoutKeySessions(
    Store<AppState> store, Room room) {
  final roomUserIds = room.userIds;
  final currentUser = store.state.authStore.user;
  final deviceKeys = store.state.cryptoStore.deviceKeys;
  final keySessions = store.state.cryptoStore.keySessions;

  // get deviceKeys for every user present in the chat
  final List<DeviceKey> roomDeviceKeys = List.from(
    roomUserIds
        .map((userId) => (deviceKeys[userId] ?? {}).values)
        .expand((x) => x),
  );

  final devieKeysWithSession = roomDeviceKeys.where(
    (deviceKey) {
      // the currentUser device doesn't need a key session for itself
      if (deviceKey.deviceId == currentUser.deviceId) return false;

      // find the identityKey for the device
      final identityKeyId = Keys.identityKeyId(deviceId: deviceKey.deviceId);
      final identityKey = deviceKey.keys![identityKeyId];

      // Key Session / Olm session already established
      if (keySessions.containsKey(identityKey)) return false;

      return true;
    },
  );

  return devieKeysWithSession.toList();
}
