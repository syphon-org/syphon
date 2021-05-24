// Dart imports:
import 'dart:async';
import 'dart:convert';

// Package imports:
import 'package:http/http.dart' as http;
import 'package:syphon/global/values.dart';

abstract class Devices {
  /// https://matrix.org/docs/spec/client_server/latest#id472
  /// 
  /// HTTP:GET
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> fetchDevices({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/devices';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await http.get(Uri.parse(url), headers: headers);

    return await json.decode(response.body);
  }

  /// https://matrix.org/docs/spec/client_server/latest#id412
  ///  
  /// HTTP:PUT
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> updateDevice({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    String? deviceId,
    String? displayName,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/devices';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final Map body = {
      'display_name': displayName,
    };

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
 * https://matrix.org/docs/spec/client_server/latest#id413
 *  
 * HTTP:DELETE
 * Gets all currently active pushers for the authenticated user.
 */
  static Future<dynamic> deleteDevice({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String? accessToken,
    String? deviceId,
    String? session,
    String? userId,
    String? authType,
    String? authValue,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/devices/$deviceId';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map? body;

    if (session != null) {
      body = {
        'auth': {
          'session': session,
          'type': authType,
          'user': userId,
          'password': authValue, // WARNING: this may not always be password?
        }
      };
    }

    final request = http.Request(
      'DELETE',
      Uri.parse(url),
    );

    request.headers.addAll(headers);

    if (body != null) {
      request.body = json.encode(body);
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(
      streamedResponse,
    );

    return await json.decode(response.body);
  }

  /**
 * https://matrix.org/docs/spec/client_server/latest#id414
 *  
 * HTTP:DELETE
 * Gets all currently active pushers for the authenticated user.
 */
  static Future<dynamic> deleteDevices({
    String? protocol = 'https://',
    String? homeserver = 'matrix.org',
    String? accessToken,
    List<String?>? deviceIds,
    String? session,
    String? userId,
    String? authType,
    String? authValue,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/delete_devices';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'devices': deviceIds,
    };

    if (session != null) {
      body['auth'] = {
        'session': session,
        'type': authType,
        'user': userId,
        'password': authValue, // WARNING: this may not always be password?
      };
    }

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}
