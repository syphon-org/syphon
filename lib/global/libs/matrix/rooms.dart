/**   
  curl -XGET "http://matrix.org/_matrix/client/r0/sync?access_token=MDAxOGxvY2F0aW9uIG1hdHJpeC5vcmcKMDAxM2lkZW50aWZpZXIga2V5CjAwMTBjaWQgZ2VuID0gMQowMDI0Y2lkIHVzZXJfaWQgPSBAZXJlaW86bWF0cml4Lm9yZwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IGJ0cmtjdC5XJkdVfkxweVAKMDAyZnNpZ25hdHVyZSDGd2cVbTYZMwapTV-smtSNHg-jwfi5iq9UFc5Kb-9Z2go" 
 */
dynamic buildSyncRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  bool fullState = false,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/sync';

  // Params
  url += '?access_token=${accessToken}';
  url += '&full_state=${fullState}';

  return {'url': url};
}

dynamic buildJoinedRoomsRequest({String accessToken}) {
  String url = '_matrix/client/r0/joined_rooms';

  // Params
  url += '?access_token=${accessToken}';

  return {'url': url};
}

dynamic buildRoomMembersRequest({String accessToken, String roomId}) {
  String url = '_matrix/client/r0/rooms/$roomId/joined_members';

  // Params
  url += '?access_token=${accessToken}';

  return {'url': url};
}

dynamic buildRoomStateRequest({
  String accessToken,
  String roomId,
}) {
  String url = '_matrix/client/r0/rooms/$roomId/state';

  // Params
  url += '?access_token=${accessToken}';

  return {'url': url};
}

dynamic buildRoomSyncRequest({String accessToken, String roomId}) {
  String url = '_matrix/client/r0/sync';
  // Params
  url += '?access_token=${accessToken}';
  url += '&filter={\"room\":{\"rooms\":["$roomId"]}}';

  return {'url': url};
}

dynamic buildRoomMessagesRequest({
  String protocol = 'https://', // http or https ( or libp2p :D )
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
  String start,
  String end,
  bool forwards = false, // Direction of events
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/messages';
  // Params
  url += '?access_token=${accessToken}';
  url += start != null ? '&from=${start}' : '';
  url += end != null ? '&to=${end}' : '';
  url += forwards ? '&dir=f' : '';

  return {'url': url};
}
