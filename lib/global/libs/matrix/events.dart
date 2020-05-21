import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class Events {
  /**
   * Fetch State Events
   * 
   * https://matrix.org/docs/spec/client_server/latest#id258
   * 
   * Get the state events for the current state of a room.
   */
  static Future<dynamic> fetchStateEvents({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state';

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
   * Fetch Message Events
   * https://matrix.org/docs/spec/client_server/latest#id261
   */
  static Future<dynamic> fetchMessageEvents({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
    String from,
    String to,
    int limit = 10,
    bool desc = true, // Direction of events
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/messages';

    // Params
    url += '?limit=$limit';
    url += from != null ? '&from=${from}' : '';
    url += to != null ? '&to=${to}' : '';
    url += desc ? '&dir=b' : '&dir=f';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }
}
