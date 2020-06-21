import 'dart:async';
import 'dart:convert';
import 'package:Tether/store/rooms/events/model.dart';
import 'package:http/http.dart' as http;

abstract class Users {
  /**
   * Fetch Account Data
   * 
   * https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-user-userid-account-data-type
   *  
   * Set some account_data for the client. This config is only visible
   * to the user that set the account_data. The config will be synced 
   * to clients in the top-level account_data.
   */
  static Future<dynamic> fetchAccountData({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
    String type = AccountDataTypes.direct,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/$type';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final saveResponse = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /**
   * Save Account Data
   * 
   * https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-user-userid-account-data-type
   * 
   * Set some account_data for the client. This config is only visible
   * to the user that set the account_data. The config will be synced 
   * to clients in the top-level account_data.
   */
  static Future<dynamic> saveAccountData({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
    String type = AccountDataTypes.direct,
    Map accountData,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/$type';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    // final body = {
    //   invites[0].userId: [newRoomId]
    // };

    final saveResponse = await http.put(
      url,
      headers: headers,
      body: json.encode(accountData),
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /**
   * Update Display Name
   * 
   * https://matrix.org/docs/spec/client_server/latest#id260
   *  
   * This API sets the given user's display name.
   *  You must have permission to set this user's display name, 
   * e.g. you need to have their access_token.
   */
  static Future<dynamic> fetchUserProfile({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/profile/$userId';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final saveResponse = await http.get(
      url,
      headers: headers,
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /**
   * Update Display Name
   * 
   * https://matrix.org/docs/spec/client_server/latest#id260
   *  
   * This API sets the given user's display name.
   *  You must have permission to set this user's display name, 
   * e.g. you need to have their access_token.
   */
  static Future<dynamic> updateDisplayName({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
    String displayName,
    Map accountData,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/profile/$userId/displayname';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "displayname": displayName,
    };

    final saveResponse = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /**
   * Update Avatar Uri
   * 
   * https://matrix.org/docs/spec/client_server/latest#id303
   *  
   * This API sets the given user's avatar URL. 
   * You must have permission to set this user's avatar URL, e.g. 
   * you need to have their access_token.
   */
  static Future<dynamic> updateAvatarUri({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String accessToken,
    String userId,
    String avatarUri,
  }) async {
    String url =
        '$protocol$homeserver/_matrix/client/r0/profile/$userId/avatar_url';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      "avatar_url": avatarUri, // mxc:// resource
    };

    final saveResponse = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      saveResponse.body,
    );
  }
}

/**
 * https://matrix.org/docs/spec/client_server/latest#id259
 * 
 * A list of members of the room. 
 * If you are joined to the room then this will be the current members of the room. 
 * If you have left the room then this will be the members of the room when you left.
 */
dynamic buildRoomMembersRequest({
  String protocol = 'https://',
  String homeserver = 'matrix.org',
  String accessToken,
  String roomId,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/rooms/${roomId}/members';

  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': url, 'headers': headers};
}
