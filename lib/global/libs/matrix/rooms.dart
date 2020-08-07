// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;

abstract class Rooms {
  /**
   * Sync (main functionality)
   * 
   * https://matrix.org/docs/spec/client_server/latest#id251
   * 
   * long polling will hang the http request until any new
   * events are found, the hang will "timeout" using the respective
   * param where you'll need to call the sync api again to wai
   * for new events
   */
  static Future<dynamic> sync({
    String protocol = 'https://', // http or https ( or libp2p :D )
    String homeserver = 'matrix.org',
    String accessToken,
    String since,
    bool fullState = false,
    String setPresence,
    int timeout = 10000,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/sync';

    // Params
    url += '?full_state=$fullState';
    url += since != null ? '&since=$since' : '';
    url += setPresence != null ? '&set_presence=$setPresence' : '';
    url += timeout != null ? '&timeout=$timeout' : '';

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
   * Sync (Background Isolate) (main functionality)
   * 
   * https://matrix.org/docs/spec/client_server/latest#id251 
   */
  static Future<dynamic> syncBackground(Map params) async {
    String protocol = params['protocol'];
    String homeserver = params['homeserver'];
    String accessToken = params['accessToken'];
    String since = params['since'];
    bool fullState = params['fullState'];
    int timeout = params['timeout'];

    return await sync(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      since: since,
      fullState: fullState,
      timeout: timeout,
    );
  }

  /** 
   * Sync (filter by roomId)
   */
  static Future<dynamic> syncRoom({
    String protocol = 'https://', // http or https ( or libp2p :D )
    String homeserver = 'matrix.org',
    String accessToken,
    String since,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/sync';

    // Params
    url += '?filter={\"room\":{\"rooms\":["$roomId"]}}';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> fetchRoomIds({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/joined_rooms';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> fetchDirectRoomIds({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/m.direct';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /*
  * Create Room - POST
  * 
  * https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-rooms-roomid-join
  *  
  * TODO: third party authentication work is needed
  */
  static Future<dynamic> joinRoom({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/join';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {};

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      response.body,
    );
  }

  /**
   * Create Room - POST
   * 
   * https://matrix.org/docs/spec/client_server/latest#id286
   * 
   * This API stops a user participating in a particular room.
   * If the user was already in the room, they will no longer
   * be able to see new events in the room. If the room requires an invite to join, 
   * they will need to be re-invited before they can re-join. If the user was invited 
   * to the room, but had not joined, this call serves to reject the invite.
   */
  static Future<dynamic> createRoom({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String name,
    String alias,
    String topic,
    String visibility = 'private',
    List<String> invites = const [],
    String chatTypePreset = "private_chat",
    bool isDirect = false,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/createRoom';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      'visibility': visibility,
      "is_direct": isDirect,
      "preset": chatTypePreset,
      'invite': invites
    };

    if (name != null) {
      body['name'] = name;
    }

    if (alias != null) {
      body['room_alias_name'] = alias;
    }

    if (topic != null) {
      body['topic'] = topic;
    }

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(
        body,
      ),
    );

    return await json.decode(
      response.body,
    );
  }

  /**
   * Leave Room - POST
   * 
   * https://matrix.org/docs/spec/client_server/latest#id286
   * 
   * This API stops a user remembering about a particular room.
   * In general, history is a first class citizen in Matrix. 
   * After this API is called, however, a user will no longer be able 
   * to retrieve history for this room. If all users on a homeserver 
   * forget a room, the room is eligible for deletion from that homeserver.
   * If the user is currently joined to the room, they must leave the room 
   * before calling this API.
   */
  static Future<dynamic> leaveRoom({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/leave';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final reponse = await http.post(
      url,
      headers: headers,
    );

    return await json.decode(
      reponse.body,
    );
  }

  /**
   * Forget Room - POST
   * 
   * https://matrix.org/docs/spec/client_server/latest#id286
   * 
   * This API stops a user remembering about a particular room.
   * In general, history is a first class citizen in Matrix. 
   * After this API is called, however, a user will no longer be able 
   * to retrieve history for this room. If all users on a homeserver 
   * forget a room, the room is eligible for deletion from that homeserver.
   * If the user is currently joined to the room, they must leave the room 
   * before calling this API.
   * 
   * Must leave room before you can forget (The Way)
   */
  static Future<dynamic> forgetRoom({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/forget';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final reponse = await http.post(
      url,
      headers: headers,
    );

    return await json.decode(
      reponse.body,
    );
  }

  /**
   * Delete Room Alias - POST
   * 
   * https://matrix.org/docs/spec/client_server/latest#id286
   * 
   * 
   * HAS NOTHING TO DO WITH DELETING ROOMS AS YOU WOULD EXPECT
   * 
   * Remove a mapping of room alias to room ID. Servers may choose 
   * to implement additional access control checks here, for instance
   * that room aliases can only be deleted by their creator or a 
   * server administrator.
   *  
   */
  static Future<dynamic> deleteRoomAlias({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String roomAlias,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/directory/room/$roomAlias';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final reponse = await http.delete(
      url,
      headers: headers,
    );

    return await json.decode(
      reponse.body,
    );
  }
}
