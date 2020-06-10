import 'dart:async';
import 'dart:convert';
import 'package:Tether/global/libs/matrix/encryption.dart';
import 'package:http/http.dart' as http;

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
  static Future<dynamic> sendEvent({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    Map event,
    String eventType,
    String trxId = '0', // just a random string to denote uniqueness
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/$eventType/$trxId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(event),
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
  static Future<dynamic> sendDirectToDevice({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String eventType,
    String trxId = '0', // just a random string to denote uniqueness
    Map event,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/sendToDevice/$eventType/$trxId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "body": event['body'],
      "msgtype": event['type'],
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
  static Future<dynamic> sendReadReceipt({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String receiptType,
    String messageId,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/receipt/$receiptType/$messageId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode({}),
    );

    return await json.decode(response.body);
  }
}
