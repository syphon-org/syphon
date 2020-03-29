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
  String requestId,
  final body,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/send/$eventType/$requestId';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}
