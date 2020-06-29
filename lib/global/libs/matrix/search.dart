import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/**
 * https://matrix.org/docs/spec/client_server/latest#id295
 * 10.5.3   GET /_matrix/client/r0/publicRooms
 * 
 * Lists the public rooms on the server. This API returns paginated responses. 
 * The rooms are ordered by the number of joined members, with the largest rooms first.
 * 
 * Response {
 *  'chunk' : [],
 *  'next_batch': XXX
 *  'total_room_count_estimate': 17960
 * }
 */

class Search {
  static FutureOr<dynamic> searchUsers({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String searchText,
    String since,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/user_directory/search';
    Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

    Map body = {
      "limit": 10,
      "search_term": searchText,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return json.decode(response.body);
  }

  static FutureOr<dynamic> searchRooms({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String searchText,
    String since,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/publicRooms';
    Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

    Map body = {
      "limit": 20,
      "filter": {
        "generic_search_term": searchText,
      },
    };

    if (since != null) {
      body['since'] = since;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return json.decode(response.body);
  }
}
