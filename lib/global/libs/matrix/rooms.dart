/**   
  curl -XGET "http://matrix.org/_matrix/client/r0/sync?access_token=MDAxOGxvY2F0aW9uIG1hdHJpeC5vcmcKMDAxM2lkZW50aWZpZXIga2V5CjAwMTBjaWQgZ2VuID0gMQowMDI0Y2lkIHVzZXJfaWQgPSBAZXJlaW86bWF0cml4Lm9yZwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IGJ0cmtjdC5XJkdVfkxweVAKMDAyZnNpZ25hdHVyZSDGd2cVbTYZMwapTV-smtSNHg-jwfi5iq9UFc5Kb-9Z2go" 
 */
dynamic buildSyncRequest({
  String accessToken,
  bool fullState = false,
}) {
  String url = '_matrix/client/r0/sync';

  // Params
  url += '?access_token=${accessToken}';
  url += '&full_state=${fullState}';

  return {'url': url};
}

dynamic buildJoinedRoomsRequest({
  String accessToken,
}) {
  String url = '_matrix/client/r0/joined_rooms';

  // Params
  url += '?access_token=${accessToken}';

  return {'url': url};
}
