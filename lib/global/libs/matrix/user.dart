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

/**
 * https://matrix.org/docs/spec/client_server/latest#id260
 *  
 * This API sets the given user's display name.
 *  You must have permission to set this user's display name, 
 * e.g. you need to have their access_token.
 */
dynamic buildUpdateDisplayName({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String userId,
  String newDisplayName,
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/profile/$userId/displayname';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  Map body = {
    "displayname": newDisplayName,
  };

  return {
    'url': url,
    'headers': headers,
    'body': body,
  };
}

/**
 * https://matrix.org/docs/spec/client_server/latest#id303
 *  
 * This API sets the given user's avatar URL. 
 * You must have permission to set this user's avatar URL, e.g. 
 * you need to have their access_token.
 */
dynamic buildUpdateAvatarUrl({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String userId,
  String newAvatarUrl, // mxc:// resource
}) {
  String url =
      '$protocol$homeserver/_matrix/client/r0/profile/${userId}/avatar_url';

  Map headers = {
    'Authorization': 'Bearer $accessToken',
  };

  Map body = {
    "avatar_url": newAvatarUrl, // mxc:// resource
  };

  return {
    'url': url,
    'headers': headers,
    'body': body,
  };
}
