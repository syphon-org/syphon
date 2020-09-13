// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

// Project imports:
import 'package:syphon/global/libs/matrix/encryption.dart';
import 'package:syphon/store/rooms/events/model.dart';

abstract class Events {
  /**
   * Fetch State Events
   * 
   * https://matrix.org/docs/spec/client_server/latest#id258
   * 
   * Get the state events for the current state of a room.
   */
  static Future<dynamic> fetchStateEvents({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * Fetch Message Events
   * https://matrix.org/docs/spec/client_server/latest#id261
   */
  static Future<dynamic> fetchMessageEvents({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String from,
    String to,
    int limit = 10, // default limit by matrix
    bool desc = true, // Direction of events
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/messages';

    // Params
    url += '?limit=$limit';
    url += from != null ? '&from=${from}' : '';
    url += to != null ? '&to=${to}' : '';
    url += desc ? '&dir=b' : '&dir=f';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * Sync (Background Isolate) (main functionality)
   * 
   * https://matrix.org/docs/spec/client_server/latest#id251 
   */
  static Future<dynamic> fetchMessageEventsMapped(Map params) async {
    return await fetchMessageEvents(
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

  /**
   * Send Encrypted Message
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
   * 
   * Notes on requestId (considered a transactionId in Matrix)
   * 
   * The transaction ID for this event. 
   * Clients should generate an ID unique across requests with the same access token; 
   * it will be used by the server to ensure idempotency of requests. <- really a requestId
   */

  static Future<dynamic> sendMessageEncrypted({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String trxId,
    String roomId,
    String senderKey,
    String ciphertext,
    String sessionId,
    String deviceId,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/m.room.encrypted/$trxId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "algorithm": Algorithms.megolmv1, //  "m.megolm.v1.aes-sha2",
      "sender_key": senderKey, // "<our curve25519 device key>",
      "ciphertext": ciphertext, // "<encrypted payload>",
      "session_id": sessionId, // "<outbound group session id>",
      "device_id": deviceId, // "<our device ID>"
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Send Event (State Only)
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
   * 
   * Notes on requestId (considered a transactionId in Matrix)
   * 
   * The transaction ID for this event. 
   * Clients should generate an ID unique across requests with the same access token; 
   * it will be used by the server to ensure idempotency of requests. <- really a requestId
   */
  static Future<dynamic> sendEvent({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String eventType,
    String stateKey,
    Map content,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state/$eventType';

    url += stateKey != null ? '/$stateKey' : '';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(content),
    );

    return await json.decode(response.body);
  }

  /**
   * Send Message
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-rooms-roomid-send-eventtype-txnid
   * 
   * Notes on requestId (considered a transactionId in Matrix)
   * 
   * The transaction ID for this event. 
   * Clients should generate an ID unique across requests with the same access token; 
   * it will be used by the server to ensure idempotency of requests. <- really a requestId
   */
  static Future<dynamic> sendMessage({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String trxId,
    Map message,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/m.room.message/$trxId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "body": message['body'],
      "msgtype": message['type'] ?? 'm.text',
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Send (Event) To Device
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-sendtodevice-eventtype-txnid
   * 
   * Not intended for messages per protocol requirements
   * 
   * This endpoint is used to send send-to-device events to a set of client devices.
   * The messages to send. A map from user ID, to a map from device ID to message body. 
   * The device ID may also be *, meaning all known devices for the user.
   */
  static Future<dynamic> sendEventToDevice({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String trxId = '0', // just a random string to denote uniqueness
    String eventType,
    String userId,
    String deviceId,
    Map content,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/sendToDevice/$eventType/$trxId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    // Use astrick to send to all known devices for user
    Map body = {
      "messages": {
        '$userId': {
          '$deviceId': content,
        },
      }
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Send Typing Event 
   */
  static Future<dynamic> sendTyping({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String userId,
    bool typing,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/typing/$userId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "typing": typing,
      "timeout": 5000,
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Send Read Receipts
   * 
   * https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-rooms-roomid-receipt-receipttype-eventid
   */
  static Future<dynamic> sendReadMarkers({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String messageId,
    String lastRead,
    bool readAll = true,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/read_markers';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      'm.fully_read': readAll ? messageId : lastRead,
      'm.read': messageId,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}
