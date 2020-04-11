/** 
 * GET user profile
{
    "avatar_url": "mxc://matrix.org/SDGdghriugerRg",
    "displayname": "Alice Margatroid"
}
 */
dynamic buildUserProfileRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String userId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/profile/${userId}';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

/**
 * https://matrix.org/docs/spec/client_server/latest#id259
 * 
 * A list of members of the room. 
 * If you are joined to the room then this will be the current members of the room. 
 * If you have left the room then this will be the members of the room when you left.
 */
dynamic buildRoomMembersRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/${roomId}/members';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}

/**
 * https://matrix.org/docs/spec/client_server/latest#id260
 * 
 * This API returns a map of MXIDs to member info objects for members of the room. 
 * The current user must be in the room for it to work, 
 * unless it is an Application Service in which case any of the AS's users must be in the room. 
 * This API is primarily for Application Services and should be faster to respond than /members 
 * as it can be implemented more efficiently on the server.
 */
dynamic buildFastRoomMembersRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/rooms/${roomId}/joined_members';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}
