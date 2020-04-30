import 'dart:collection';

/**   
  curl -XGET "http://matrix.org/_matrix/client/r0/sync?access_token=MDAxOGxvY2F0aW9uIG1hdHJpeC5vcmcKMDAxM2lkZW50aWZpZXIga2V5CjAwMTBjaWQgZ2VuID0gMQowMDI0Y2lkIHVzZXJfaWQgPSBAZXJlaW86bWF0cml4Lm9yZwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IGJ0cmtjdC5XJkdVfkxweVAKMDAyZnNpZ25hdHVyZSDGd2cVbTYZMwapTV-smtSNHg-jwfi5iq9UFc5Kb-9Z2go" 
 */
dynamic buildSyncRequest({
  String protocol = 'https://', // http or https ( or libp2p :D )
  String homeserver = 'matrix.org',
  String accessToken,
  String since,
  bool fullState = false,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/sync';

  // Params
  url += '?full_state=${fullState}';
  url += since != null ? '&since=$since' : '';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildJoinedRoomsRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/joined_rooms';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildDirectRoomsRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String userId,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/m.direct';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildRoomStateRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildRoomSyncRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/sync';

  url += '?filter={\"room\":{\"rooms\":["$roomId"]}}';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

dynamic buildCreateRoom({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomName,
  String roomAlias,
  List<String> invites,
  bool isDirect,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/createRoom';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}
