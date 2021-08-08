import 'package:redux/redux.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/index.dart';

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

String selectCurrentSessionKey(Store<AppState> store) {
  final currentUser = store.state.authStore.user;
  final currentUserId = store.state.authStore.user.userId;
  final currentSessionId = store.state.authStore.user.deviceId;
  final deviceKeysOwned = store.state.cryptoStore.deviceKeysOwned;

  if (deviceKeysOwned.containsKey(currentSessionId)) {
    final currentDeviceKey = deviceKeysOwned[currentSessionId];
    final fingerprintId = Keys.fingerprintId(deviceId: currentUser.deviceId);

    final String fingerprint = currentDeviceKey?.keys?[fingerprintId] ?? Values.UNKNOWN;

    printJson(currentDeviceKey?.keys);
    return fingerprint.chunk(4);
  }

  return Values.UNKNOWN;
}
