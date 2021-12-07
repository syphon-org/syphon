import 'dart:async';
import 'dart:convert';

import 'package:syphon/global/https.dart';
import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/global/values.dart';

abstract class Events {
  /// Fetch State Events
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id258
  ///
  /// Get the state events for the current state of a room.
  static Future<dynamic> fetchStateEvents({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /// Fetch Message Events
  /// https://spec.matrix.org/latest/client-server-api/#get_matrixclientv3roomsroomidmessages
  static Future<dynamic> fetchMessageEvents({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? from,
    String? to,
    int? limit = 10, // default limit by matrix
    bool desc = true, // direction of events
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/messages';

    url += '?limit=$limit';
    url += from != null ? '&from=$from' : '';
    url += to != null ? '&to=$to' : '';
    url += desc ? '&dir=b' : '&dir=f';
    url += '&filter={"not_types":["${EventTypes.member}"]}';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(utf8.decode(response.bodyBytes));
  }

  /// Sync (Background Isolate) (main functionality)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id251
  static Future<dynamic> fetchMessageEventsThreaded(Map params) async {
    httpClient = createClient(proxySettings: params['proxySettings']);

    return fetchMessageEvents(
      protocol: params['protocol'],
      homeserver: params['homeserver'],
      accessToken: params['accessToken'],
      roomId: params['roomId'],
      to: params['to'],
      from: params['from'],
      limit: params['limit'],
      desc: params['desc'] ?? true,
    );
  }

  /// Send Encrypted Message
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
  ///
  /// Notes on requestId (considered a transactionId in Matrix)
  ///
  /// The transaction ID for this event.
  /// Clients should generate an ID unique across requests with the same access token;
  /// it will be used by the server to ensure idempotency of requests. <- really a requestId

  static Future<dynamic> sendMessageEncrypted({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    Map? unencryptedData,
    String? accessToken,
    String? trxId,
    String? roomId,
    String? senderKey,
    String? ciphertext,
    String? sessionId,
    String? deviceId,
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/m.room.encrypted/$trxId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'algorithm': Algorithms.megolmv1, //  'm.megolm.v1.aes-sha2',
      'sender_key': senderKey, // '<our curve25519 device key>',
      'ciphertext': ciphertext, // '<encrypted payload>',
      'session_id': sessionId, // '<outbound group session id>',
      'device_id': deviceId, // '<our device ID>'
    };

    if (unencryptedData != null) {
      body.addAll(unencryptedData);
    }

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Send Event (State Only)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
  ///
  /// Notes on requestId (considered a transactionId in Matrix)
  ///
  /// The transaction ID for this event.
  /// Clients should generate an ID unique across requests with the same access token;
  /// it will be used by the server to ensure idempotency of requests. <- really a requestId
  static Future<dynamic> sendEvent({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? eventType,
    String? stateKey,
    Map? content,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state/$eventType';

    url += stateKey != null ? '/$stateKey' : '';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(content),
    );

    return await json.decode(response.body);
  }

  /// Send Message
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
  ///
  /// Notes on requestId (considered a transactionId in Matrix)
  ///
  /// The transaction ID for this event.
  /// Clients should generate an ID unique across requests with the same access token;
  /// it will be used by the server to ensure idempotency of requests. <- really a requestId
  static Future<dynamic> sendMessage({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? trxId,
    Map? message,
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/m.room.message/$trxId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'body': message!['body'],
      'msgtype': message['msgtype'] ?? 'm.text',
    };

    if (message['format'] != null) {
      body['format'] = message['format'];
    }

    if (message['m.relates_to'] != null) {
      body['m.relates_to'] = message['m.relates_to'];
    }

    if (message['formatted_body'] != null) {
      body['formatted_body'] = message['formatted_body'];
    }

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(message),
    );

    return await json.decode(response.body);
  }

  /// Send Reaction
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
  ///
  /// Notes on requestId (considered a transactionId in Matrix)
  ///
  /// The transaction ID for this event.
  /// Clients should generate an ID unique across requests with the same access token;
  /// it will be used by the server to ensure idempotency of requests. <- really a requestId
  static Future<dynamic> sendReaction({
    String protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? reaction,
    String? roomId,
    String? messageId,
    String? trxId,
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/m.reaction/$trxId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'm.relates_to': {'rel_type': 'm.annotation', 'event_id': messageId, 'key': reaction}
    };

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  ///
  /// Redact Event
  ///
  /// For all types of sendable events
  ///
  static Future<dynamic> redactEvent({
    String protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? eventId,
    String? trxId,
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/redact/$eventId/$trxId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {};

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Send (Event) To Device
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-sendtodevice-eventtype-txnid
  ///
  /// Not intended for messages per protocol requirements
  ///
  /// This endpoint is used to send send-to-device events to a set of client devices.
  /// The messages to send. A map from user ID, to a map from device ID to message body.
  /// The device ID may also be *, meaning all known devices for the user.
  static Future<dynamic> sendEventToDevice({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String trxId = '0', // just a random string to denote uniqueness
    String? eventType,
    String? userId,
    String? deviceId,
    Map? content,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/sendToDevice/$eventType/$trxId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    // Use astrick to send to all known devices for user
    final Map body = {
      'messages': content,
    };

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Send Typing Event
  static Future<dynamic> sendTyping({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? userId,
    bool? typing,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/typing/$userId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'typing': typing,
      'timeout': 5000,
    };

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Send Read Receipts
  ///
  /// https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-rooms-roomid-receipt-receipttype-eventid
  static Future<dynamic> sendReadMarkers({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? messageId,
    String? lastRead,
    bool readAll = true,
    bool hidden = false,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/read_markers';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'm.fully_read': readAll ? messageId : lastRead,
      'm.read': messageId,
      'm.hidden': hidden,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Delete Message - PUT
  /// https://matrix.org/docs/spec/client_server/r0.6.1#m-room-redaction
  static Future<dynamic> deleteMessage({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? eventId,
    String? txnId,

  })async{
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/redact/$eventId/';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {};

    final response = await httpClient.put(Uri.parse(url), headers:  headers, body: json.encode(body));

    return await json.decode(
      response.body,
    );
  }

}
