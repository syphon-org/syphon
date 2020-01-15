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
