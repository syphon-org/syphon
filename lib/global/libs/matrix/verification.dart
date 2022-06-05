import 'dart:async';

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
    String? deviceId,
    Map? content,
  }) async {
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

    return MatrixApi.sendEventToDevice(
      trxId: randomString(25),
      protocol: protocol,
      accessToken: accessToken,
      content: payload,
    );
  }

  /// https://spec.matrix.org/v1.2/client-server-api/#mkeyverificationrequest
  ///
  /// HTTP:GET
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> markVerificationReady({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? deviceId,
    String? relatedEventId,
    Map? content,
  }) async {
    // format payload for toDevice events
    final payload = {
      'content': {
        // The device ID which is initiating the request.
        'from_device': deviceId,
        'methods': ['m.sas.v1'],
        'timestamp': DateTime.now().microsecondsSinceEpoch,
        'transaction_id': randomString(25)
      },
      'm.relates_to': {
        'rel_type': 'm.reference',
        'event_id': relatedEventId,
      },
      'type': 'm.key.verification.ready'
    };

    return MatrixApi.sendEventToDevice(
      trxId: randomString(25),
      protocol: protocol,
      accessToken: accessToken,
      content: payload,
    );
  }

  /// https://matrix.org/docs/spec/client_server/latest#id472
  ///
  /// HTTP:GET
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> startVerification({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? deviceId,
    String? relatedEventId,
    Map? content,
  }) async {
    // format payload for toDevice events
    final payload = {
      'content': {
        // The device ID which is initiating the request.
        'from_device': deviceId,
        'method': 'm.sas.v1',
        'timestamp': DateTime.now().microsecondsSinceEpoch,
        'transaction_id': randomString(25)
      },
      'm.relates_to': {
        'rel_type': 'm.reference',
        'event_id': relatedEventId,
      },
      'type': 'm.key.verification.start'
    };

    return MatrixApi.sendEventToDevice(
      trxId: randomString(25),
      protocol: protocol,
      accessToken: accessToken,
      content: payload,
    );
  }
}
