/** 
 * GET user profile
{
    "avatar_url": "mxc://matrix.org/SDGdghriugerRg",
    "displayname": "Alice Margatroid"
}
 */
dynamic buildUserProfileRequest({String userId}) {
  String url = '/_matrix/client/r0/profile/${userId}';
  return {'url': url};
}
