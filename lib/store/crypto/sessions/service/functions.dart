import 'dart:io';

import 'package:intl/intl.dart';
import 'package:olm/olm.dart' as olm;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/crypto/keys/models.dart';
import 'package:syphon/store/crypto/sessions/converters.dart';
import 'package:syphon/store/crypto/sessions/model.dart';

Future<bool> exportSessionKeysThreaded({
  required String location,
  required String password,
  required Map<String, Map<String, DeviceKey>> deviceKeys,
  required Map<String, Map<String, List<MessageSession>>> messageSessions,
}) async {
  // create file
  var directory = await getApplicationDocumentsDirectory();

  if (Platform.isAndroid) {
    directory = location.isEmpty
        ? Directory(Values.ANDROID_DEFAULT_DIRECTORY)
        : Directory(location);
  }

  if (Platform.isIOS) {
    directory = location.isEmpty
        ? directory
        : Directory(
            location,
          );
  }

  final deviceKeysByDeviceId = deviceKeys.values
      .toList()
      .fold<Map<String, DeviceKey>>(<String, DeviceKey>{},
          (previous, current) => previous..addAll(current));

  final deviceKeyIdentities = Map.fromIterable(
    deviceKeysByDeviceId.values,
    key: (device) => (device as DeviceKey).curve25519,
    value: (device) => (device as DeviceKey).ed25519,
  );

  final sessionData = [];

  // prepend session keys to an array per spec
  for (final roomSessions in messageSessions.entries) {
    final roomId = roomSessions.key;
    final sessions = roomSessions.value;

    for (final messsageSessions in sessions.entries) {
      final identityKey = messsageSessions.key;
      final sessionsSerialized = messsageSessions.value;
      final deviceKeyEd25519 = deviceKeyIdentities[identityKey];

      for (final session in sessionsSerialized) {
        final messageIndex = session.index;

        // attempt to decrypt with any existing sessions
        final inboundSession = olm.InboundGroupSession()
          ..unpickle(roomId, session.serialized);

        // session
        final sessionId = inboundSession.session_id();
        final sessionKey = inboundSession.export_session(messageIndex);

        sessionData.add({
          'algorithm': Algorithms.megolmv1,
          // TODO: support needed alongside m.forwarded_room_key events.
          'forwarding_curve25519_key_chain': [],
          'room_id': roomId,
          'sender_key': identityKey,
          'sender_claimed_keys': {
            'ed25519': deviceKeyEd25519,
          },
          'session_id': sessionId,
          'session_key': sessionKey,
        });
      }
    }
  }

  // for debugging only
  if (DEBUG_MODE) {
    log.json({
      'context': 'worker',
      'sessionData': sessionData,
    });
  }

  // encrypt exported session keys
  final String encryptedExport = await encryptSessionKeys(
    sessionJson: sessionData,
    password: password,
  );

  final currentTime = DateTime.now();
  final formattedTime =
      DateFormat('MMM_dd_yyyy_hh_mm_aa').format(currentTime).toLowerCase();
  final fileName =
      '${Values.appName}_key_backup_$formattedTime.txt'.toLowerCase();

  final file = File('${directory.path}/$fileName');

  await file.writeAsString(encryptedExport);

  return true;
}
