dynamic buildRoomMessagesRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
  String start,
  int limit = 10,
  String end,
  bool desc = true, // Direction of events
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/messages';

  // Params
  url += '?limit=$limit';
  url += start != null ? '&from=${start}' : '';
  url += end != null ? '&to=${end}' : '';
  url += desc ? '&dir=b' : '&dir=f';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

/**
 * Notes on requestId (considered a transactionId in Matrix)
 * 
 * The transaction ID for this event. 
 * Clients should generate an ID unique across requests with the same access token; 
 * it will be used by the server to ensure idempotency of requests. <- really a requestId
 */
dynamic buildSendMessageRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
  String eventType = 'm.room.message',
  String messageType = 'm.text',
  String requestId,
  final messageBody,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/$eventType/$requestId';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  Map body = {
    "msgtype": messageType,
    "body": messageBody,
  };

  return {
    'url': url,
    'headers': headers,
    'body': body,
  };
}

/**
 * Notes on requestId (considered a transactionId in Matrix)
 * 
 * The transaction ID for this event. 
 * Clients should generate an ID unique across requests with the same access token; 
 * it will be used by the server to ensure idempotency of requests. <- really a requestId
 */
dynamic buildSendTypingRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
  String userId,
  bool typing,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/rooms/${roomId}/typing/${userId}';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  Map body = {
    "typing": typing,
    "timeout": 5000,
  };

  return {
    'url': url,
    'headers': headers,
    'body': body,
  };
}

/**
 * Send a read receipt for a message
 * 
*  https://matrix.org/docs/spec/client_server/latest#id373
 * POST /_matrix/client/r0/rooms/{roomId}/receipt/{receiptType}/{eventId}
 */
dynamic buildSendReadReceipt({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
  String receiptType,
  String messageId,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/rooms/${roomId}/receipt/${receiptType}/${messageId}';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': url,
    'headers': headers,
  };
}
