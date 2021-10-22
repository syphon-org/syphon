import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:syphon/global/https.dart';
import 'package:syphon/global/values.dart';

abstract class Notifications {
  /// Fetch Notification Pushers
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-pushers
  ///
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> fetchNotifications({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? from,
    int limit = 10,
    String? only,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/notifications';

    // Params
    url += '?limit=$limit';
    url += from != null ? '&from=$from' : '';
    url += only != null ? '&only=$only' : '';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /// Fetch Notification Pushers
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-pushers
  ///
  /// Gets all currently active pushers for the authenticated user.
  static Future<dynamic> fetchNotificationPushers({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/pushers';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    final response = await httpClient.get(
      Uri.parse(url),
      headers: headers,
    );

    return await json.decode(response.body);
  }

  /**
   * 
      {
        "lang": "en",
        "kind": "http",
        "app_display_name": "Mat Rix",
        "device_display_name": "iPhone 9",
        "profile_tag": "xxyyzz",
        "app_id": "com.example.app.ios",
        "pushkey": "APA91bHPRgkF3JUikC4ENAHEeMrd41Zxv3hVZjC9KtT8OvPVGJ-hQMRKRrZuJAEcl7B338qju59zJMjw2DELjzEvxwYv7hH5Ynpc1ODQ0aT4U4OFEeco8ohsN5PjL1iC2dNtk2BAokeMCg2ZXKqpc8FXKmhX94kIxQ",
        "data": {
          "url": "https://push-gateway.location.here/_matrix/push/v1/notify",
          "format": "event_id_only"
        },
        "append": false
      }
    */
  /// Save Notification Pusher
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-pushers
  ///
  /// This endpoint allows the creation, modification and deletion of pushers for
  /// this user ID. The behaviour of this endpoint varies depending on the values
  /// in the JSON body.
  static Future<dynamic> saveNotificationPusher({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? accessToken,
    String? pushKey, // required
    String? kind = 'http', // required
    String? appId, // required
    String? appDisplayName, // required
    String? deviceDisplayName, // required
    String? profileTag,
    String? lang, // required
    String? dataUrl, // required
    String? append,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/pushers/set';
    final String pushGateway = '$protocol$homeserver/_matrix/push/v1/notify';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'lang': 'en',
      'kind': kind,
      'app_display_name': appDisplayName,
      'device_display_name': deviceDisplayName,
      'app_id': appId,
      'pushkey': pushKey,
      'data': {
        'url': pushGateway,
        'format': 'event_id_only',
      },
      'append': false
    };

    if (profileTag != null) {
      body['profile_tag'] = profileTag;
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}
