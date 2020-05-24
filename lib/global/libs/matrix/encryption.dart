import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class Encryption {
  /**
   * Fetch Encryption Keys
   * 
   * https://matrix.org/docs/spec/client_server/latest#id460
   * 
   * Returns the current devices and identity keys for the given users.
   */
  static Future<dynamic> fetchKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String lastSince,
    int timeout = 10 * 1000, // 10 seconds
    List<String> deviceKeys = const [],
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/query';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.post(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * 
   * Fetch Key Changes
   * 
   * https://matrix.org/docs/spec/client_server/latest#id462
   * 
   * Gets a list of users who have updated their device identity keys since a previous sync token.
   * 
   * The server should include in the results any users who:
   *   - currently share a room with the calling user (ie, both users have membership state join); and
   *   - added new device identity keys or removed an existing device with identity keys, between from and to.
   * 
   */
  static Future<dynamic> fetchKeyChanges({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String from,
    String to,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/claim';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * Claim Keys
   * 
   * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-keys-changes
   * 
   * Claims one-time keys for use in pre-key messages.
   * 
   */
  static Future<dynamic> claimKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    Map oneTimeKeys,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/claim';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.post(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> uploadKeys({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    Map oneTimeKeys,
    List<String> deviceKeys,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/keys/upload';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.post(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }
}
