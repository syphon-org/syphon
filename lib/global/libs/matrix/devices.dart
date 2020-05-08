/**
 * https://matrix.org/docs/spec/client_server/latest#id472
 * 
 * Gets all currently active pushers for the authenticated user.
 */
dynamic buildDevicesRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/devices';

  Map<String, String> headers = {
    'Authorization': 'Bearer $accessToken',
  };

  return {
    'url': url,
    'headers': headers,
  };
}
