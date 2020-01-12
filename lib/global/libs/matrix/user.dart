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

  // Params
  url += '?access_token=${accessToken}';

  return {'url': url};
}
