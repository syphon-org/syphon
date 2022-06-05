import 'dart:async';
import 'dart:math';

import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';

abstract class Verification {
  /// https://matrix.org/docs/spec/client_server/latest#id472
  ///
  /// HTTP:GET
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> requestVerification({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String trxId = '0', // just a random string to denote uniqueness
    String? eventType,
    String? userId,
    String? deviceId,
    Map? content,
  }) async {
    final randomNumber = Random.secure().nextInt(1 << 31).toString();

    // format payload for toDevice events
    final payload = {
      'content': {
        // The device ID which is initiating the request.
        'from_device': deviceId,
        'methods': ['m.sas.v1'],
        'timestamp': DateTime.now().microsecondsSinceEpoch,
        'transaction_id': randomString(25)
      },
      'type': 'm.key.verification.request'
    };

    return await MatrixApi.sendEventToDevice(
      trxId: randomNumber,
      protocol: protocol,
      accessToken: accessToken,
    );
  }
}
