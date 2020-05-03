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

/**
 * Create Room - POST
 * 
 * https://matrix.org/docs/spec/client_server/latest#id286
 * 
 * This API stops a user participating in a particular room.
 * If the user was already in the room, they will no longer
 * be able to see new events in the room. If the room requires an invite to join, 
 * they will need to be re-invited before they can re-join. If the user was invited 
 * to the room, but had not joined, this call serves to reject the invite.
 */
dynamic buildCreateRoom({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomName,
  String roomAlias,
  String roomTopic,
  List<String> invites = const [],
  String chatTypePreset = "private_chat",
  bool isDirect = false,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/createRoom';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  Map body = {
    "name": roomName,
    "is_direct": isDirect,
    "preset": chatTypePreset,
    'invite': invites
  };

  // if (roomAlias != null) {
  //   body['room_alias_name:'] = roomAlias;
  // }
  // if (roomTopic != null) {
  //   body['topic'] = roomTopic;
  // }

  return {
    'url': url,
    'headers': headers,
    'body': body,
  };
}

/**
 * Leave (or Reject) Room - POST
 * 
 * https://matrix.org/docs/spec/client_server/latest#id286
 * 
 * This API stops a user participating in a particular room.
 * If the user was already in the room, they will no longer
 * be able to see new events in the room. If the room requires an invite to join, 
 * they will need to be re-invited before they can re-join. If the user was invited 
 * to the room, but had not joined, this call serves to reject the invite.
 */
dynamic buildLeaveRoom({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/leave';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': url,
    'headers': headers,
  };
}

/**
 * Forget Room - POST
 * 
 * https://matrix.org/docs/spec/client_server/latest#id286
 * 
 * This API stops a user remembering about a particular room.
 * In general, history is a first class citizen in Matrix. 
 * After this API is called, however, a user will no longer be able 
 * to retrieve history for this room. If all users on a homeserver 
 * forget a room, the room is eligible for deletion from that homeserver.
 * If the user is currently joined to the room, they must leave the room 
 * before calling this API.
 */
dynamic buildForgetRoom({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/forget';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': url,
    'headers': headers,
  };
}

/**
 * Delete Room Alias - DELETE
 * 
 * https://matrix.org/docs/spec/client_server/latest#id277
 * 
 * Remove a mapping of room alias to room ID. Servers may choose 
 * to implement additional access control checks here, for instance
 * that room aliases can only be deleted by their creator or a 
 * server administrator.
 */

dynamic buildDeleteRoomAlias({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomAlias,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/directory/room/$roomAlias';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': url,
    'headers': headers,
  };
}
