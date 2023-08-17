import 'dart:async';

import 'package:syphon/domain/sync/service/storage.dart';
import 'package:syphon/global/libraries/matrix/index.dart';

Future<Map<String, String>> updateRoomNames({
  required String protocol,
  required String homeserver,
  required String accessToken,
  required String roomId,
  Map<String, String> roomNames = const {},
}) async {
  try {
    final roomNameList = await MatrixApi.fetchRoomName(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      roomId: roomId,
    );

    final roomAlias = roomNameList[roomNameList.length - 1];
    final roomName = roomAlias.replaceAll('#', '').replaceAll(r'\:.*', '');

    roomNames[roomId] = roomName;

    saveRoomNames(roomNames: roomNames);
    return roomNames;
  } catch (error) {
    // ignore: avoid_print
    print('[backgroundSyncLoop] failed to fetch & parse room name $roomId');
    return {};
  }
}
