import 'dart:async';
import 'dart:convert';

import 'package:syphon/global/https.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/rooms/room/model.dart';
import 'package:syphon/store/settings/proxy-settings/model.dart';

abstract class Rooms {
  /// Sync (main functionality)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id251
  ///
  /// long polling will hang the http request until any new
  /// events are found, the hang will "timeout" using the respective
  /// param where you'll need to call the sync api again to wai
  /// for new events
  static Future<dynamic> sync({
    String? protocol = 'https://', // http or https ( or libp2p :D )
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? since,
    bool? fullState = false,
    String? setPresence,
    int? timeout = 10000,
    String? filter,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/sync';

    final fullSync = since == null && filter == null;

    // Params
    url += '?full_state=$fullState';
    url += since != null ? '&since=$since' : '';
    url += setPresence != null ? '&set_presence=$setPresence' : '';
    url += timeout != null ? '&timeout=$timeout' : '';
    url += filter != null ? '&filter=$filter' : '';
    url += fullSync
        ? '&filter={"room":{"state": {"lazy_load_members":true}, "timeline": {"lazy_load_members":true}}}'
        : '';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient
        .get(
          Uri.parse(url),
          headers: headers,
        )
        .timeout(
          Duration(seconds: fullSync ? 180 : 60),
        );

    return await json.decode(utf8.decode(response.bodyBytes));
  }

  /// Sync (Background Isolate) (main functionality)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id251
  static Future<dynamic> syncThreaded(Map params) async {
    final String? protocol = params['protocol'];
    final String? homeserver = params['homeserver'];
    final String? accessToken = params['accessToken'];
    final String? since = params['since'];
    final bool? fullState = params['fullState'];
    final int? timeout = params['timeout'];
    final String? filter = params['filter'];
    final ProxySettings? proxySettings = params['proxySettings'];

    httpClient = createClient(proxySettings: proxySettings);

    return sync(
      protocol: protocol,
      homeserver: homeserver,
      accessToken: accessToken,
      since: since,
      fullState: fullState,
      timeout: timeout,
      filter: filter,
    );
  }

  /// Sync (filter by roomId)
  static Future<dynamic> syncRoom({
    String protocol = 'https://', // http or https ( or libp2p :D )
    String homeserver = Values.homeserverDefault,
    String? accessToken,
    String? since,
    String? roomId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/sync';

    // Params
    url += '?filter={"room":{"rooms":["$roomId"]}}';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(utf8.decode(response.bodyBytes));
  }

  static Future<dynamic> fetchRoomIds({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/joined_rooms';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> fetchMembersAll({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/joined_members';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> fetchDirectRoomIds({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/m.direct';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /*
  * Create Room - POST
  * 
  * https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-rooms-roomid-join
  * 
  */
  static Future<dynamic> joinRoom({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final parts = roomId!.split(':');
    final serverName = parts.isNotEmpty ? parts[1] : homeserver;
    final roomIdFormatted = Uri.encodeComponent(roomId);

    final String url =
        '$protocol$homeserver/_matrix/client/r0/join/$roomIdFormatted?server_name=$serverName';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({}),
    );

    return await json.decode(response.body);
  }

  /// Create Room - POST
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id286
  ///
  /// This API stops a user participating in a particular room.
  /// If the user was already in the room, they will no longer
  /// be able to see new events in the room. If the room requires an invite to join,
  /// they will need to be re-invited before they can re-join. If the user was invited
  /// to the room, but had not joined, this call serves to reject the invite.
  static Future<dynamic> createRoom({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? name,
    String? alias,
    String? topic,
    String visibility = 'private',
    List<String?> invites = const [],
    String chatTypePreset = 'private_chat',
    bool isDirect = false,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/createRoom';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'visibility': visibility,
      'is_direct': isDirect,
      'preset': chatTypePreset,
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

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Leave Room - POST
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id286
  ///
  /// This API stops a user remembering about a particular room.
  /// In general, history is a first class citizen in Matrix.
  /// After this API is called, however, a user will no longer be able
  /// to retrieve history for this room. If all users on a homeserver
  /// forget a room, the room is eligible for deletion from that homeserver.
  /// If the user is currently joined to the room, they must leave the room
  /// before calling this API.
  static Future<dynamic> leaveRoom({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/leave';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final reponse = await httpClient.post(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(
      reponse.body,
    );
  }

  /// Forget Room - POST
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id286
  ///
  /// This API stops a user remembering about a particular room.
  /// In general, history is a first class citizen in Matrix.
  /// After this API is called, however, a user will no longer be able
  /// to retrieve history for this room. If all users on a homeserver
  /// forget a room, the room is eligible for deletion from that homeserver.
  /// If the user is currently joined to the room, they must leave the room
  /// before calling this API.
  ///
  /// Must leave room before you can forget (The Way)
  static Future<dynamic> forgetRoom({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/forget';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /// Delete Room Alias - POST
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id286
  ///
  ///
  /// HAS NOTHING TO DO WITH DELETING ROOMS AS YOU WOULD EXPECT
  ///
  /// Remove a mapping of room alias to room ID. Servers may choose
  /// to implement additional access control checks here, for instance
  /// that room aliases can only be deleted by their creator or a
  /// server administrator.
  ///
  static Future<dynamic> deleteRoomAlias({
    String protocol = 'https://',
    String homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomAlias,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/directory/room/$roomAlias';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final reponse = await httpClient.delete(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(
      reponse.body,
    );
  }

  ///
  /// Create Room Filter (Lazy Loading) - POST
  ///
  /// Create a filter to use when fetching room state, messages, or /sync'ing
  ///
  /// https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-user-userid-filter
  ///
  static Future<dynamic> createFilter({
    String protocol = 'https://',
    String homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    bool lazyLoading = false,
    Map? filters,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/user/$userId/filter';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    Map? body = filters;

    if (lazyLoading) {
      body = {
        'room': {
          'state': {'lazy_load_members': true},
        }
      };
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Create Room Filter (Lazy Loading) - POST
  ///
  /// https://matrix.org/docs/spec/client_server/latest#post-matrix-client-r0-user-userid-filter
  ///
  /// Create a filter to use when fetching room state, messages, or /sync'ing
  static Future<dynamic> fetchFilter({
    String protocol = 'https://',
    String homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomAlias,
    String? filterId,
    String? userId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/user/$userId/filter/$filterId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final reponse = await httpClient.post(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(reponse.body);
  }

  ///
  /// Fetch Room Name
  ///
  /// Unauthenticated access to room info for the purpose
  /// of fetching room names where needed in external to the
  /// main thread
  ///
  ///
  static Future<dynamic> fetchRoomName({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/aliases';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  // https://matrix.org/docs/spec/client_server/r0.2.0#m-room-power-levels
  static Future<dynamic> fetchPowerLevels({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    Room? room,}) async{

    final String roomId = room!.id;

    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/state/m.room.power_levels/';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

}
