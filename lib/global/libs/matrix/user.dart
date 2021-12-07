import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:syphon/global/https.dart';

import 'package:syphon/global/libs/matrix/constants.dart';
import 'package:syphon/global/values.dart';

abstract class Users {
  ///
  /// Fetch Account Data
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-user-userid-account-data-type
  ///
  /// Set some account_data for the client. This config is only visible
  /// to the user that set the account_data. The config will be synced
  /// to clients in the top-level account_data.
  ///
  static Future<dynamic> fetchAccountData({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    String type = AccountDataTypes.direct,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/$type';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final saveResponse = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /// Save Account Data
  ///
  /// https://matrix.org/docs/spec/client_server/latest#put-matrix-client-r0-user-userid-account-data-type
  ///
  /// Set some account_data for the client. This config is only visible
  /// to the user that set the account_data. The config will be synced
  /// to clients in the top-level account_data.
  static Future<dynamic> saveAccountData({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    String type = AccountDataTypes.direct,
    Map? accountData,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/$type';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final saveResponse = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(accountData),
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /// Ignore User (a.k.a. Block User)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#m-ignored-user-list
  ///
  /// Set some account_data for the client. This config is only visible
  /// to the user that set the account_data. The config will be synced
  /// to clients in the top-level account_data.
  static Future<dynamic> updateBlockedUsers({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    Map<String, dynamic> blockUserList = const {},
  }) async {
    final String url =
        '$protocol$homeserver/_matrix/client/r0/user/$userId/account_data/${AccountDataTypes.ignoredUserList}';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final body = {
      'ignored_users': blockUserList,
    };

    final saveResponse = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /// Ignore User (a.k.a. Block User)
  ///
  /// https://matrix.org/docs/spec/client_server/latest#m-ignored-user-list
  ///
  /// Set some account_data for the client. This config is only visible
  /// to the user that set the account_data. The config will be synced
  /// to clients in the top-level account_data.
  static Future<dynamic> inviteUser({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? roomId,
    String? userId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/invite';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final body = {
      'user_id': userId,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Update Display Name
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id260
  ///
  /// This API sets the given user's display name.
  ///  You must have permission to set this user's display name,
  /// e.g. you need to have their access_token.
  static Future<dynamic> fetchUserProfile({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/profile/$userId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(utf8.decode(response.bodyBytes));
  }

  /// Update Display Name
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id260
  ///
  /// This API sets the given user's display name.
  ///  You must have permission to set this user's display name,
  /// e.g. you need to have their access_token.
  static Future<dynamic> updateDisplayName({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    String? displayName,
    Map? accountData,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/profile/$userId/displayname';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final Map body = {
      'displayname': displayName,
    };

    final response = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Update Avatar Uri
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id303
  ///
  /// This API sets the given user's avatar URL.
  /// You must have permission to set this user's avatar URL, e.g.
  /// you need to have their access_token.
  static Future<dynamic> updateAvatarUri({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    String? avatarUri,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/profile/$userId/avatar_url';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final Map body = {
      'avatar_url': avatarUri, // mxc:// resource
    };

    final saveResponse = await httpClient.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      saveResponse.body,
    );
  }

  /// Update Avatar Uri
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id303
  ///
  /// This API sets the given user's avatar URL.
  /// You must have permission to set this user's avatar URL, e.g.
  /// you need to have their access_token.
  static Future<dynamic> deactivateUser({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? userId,
    String? identityServer,
    String? session,
    String? authType,
    String? authValue,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/account/deactivate';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {'id_server': identityServer};

    if (session != null) {
      body['auth'] = {
        'session': session,
        'type': authType,
        'user': userId,
        'password': authValue, // WARNING: this may not always be password?
      };
    }

    final saveResponse = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(
      saveResponse.body,
    );
  }
}

/// https://matrix.org/docs/spec/client_server/latest#id259
///
/// A list of members of the room.
/// If you are joined to the room then this will be the current members of the room.
/// If you have left the room then this will be the members of the room when you left.
dynamic buildRoomMembersRequest({
  String protocol = 'https://',
  String homeserver = Values.homeserverDefault,
  String? accessToken,
  String? roomId,
}) {
  final String url = '$protocol$homeserver/_matrix/client/r0/rooms/$roomId/members';

  final Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};

  return {'url': Uri.parse(url), 'headers': headers};
}
