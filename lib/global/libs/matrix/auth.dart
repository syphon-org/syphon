import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:syphon/global/https.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/global/values.dart';

/// https://matrix.org/docs/spec/client_server/latest#id183
///
/// Authentication Types
///
/// Can be used during actual login or interactive auth for confirmation
class MatrixAuthTypes {
  static const PASSWORD = 'm.login.password';
  static const RECAPTCHA = 'm.login.recaptcha';
  static const TOKEN = 'm.login.token';
  static const TERMS = 'm.login.terms';
  static const DUMMY = 'm.login.dummy';
  static const SSO = 'm.login.sso';
  static const EMAIL = 'm.login.email.identity';
}

enum AuthTypes {
  Password,
  SSO,
}

abstract class Auth {
  static const NEEDS_INTERACTIVE_AUTH = 'needs_interactive_auth';

  static Future<dynamic> loginType({
    required String protocol,
    required String homeserver,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/login';

    final response = await httpClient.get(Uri.parse(url));

    return await json.decode(response.body);
  }

  ///
  /// Login User
  ///
  /// Gets the homeserver's supported login types to authenticate
  /// users. Clients should pick one of these and supply it as
  /// the type when logging in.
  ///
  /// https://matrix.org/docs/spec/client_server/latest#get-matrix-client-r0-login
  ///
  static Future<dynamic> loginUser({
    required String protocol,
    required String homeserver,
    String type = 'm.login.password',
    String? username,
    String? password,
    String? deviceId,
    String? deviceName,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/login';

    final Map body = {
      'type': type,
      'identifier': {'type': 'm.id.user', 'user': username},
      'password': password,
    };

    if (deviceId != null) {
      body['device_id'] = deviceId;
    }

    if (deviceName != null) {
      body['initial_device_display_name'] = deviceName;
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  ///
  /// https://matrix.org/docs/spec/client_server/latest#id198
  ///
  /// Login User
  ///
  /// Gets the homeserver's supported login types to authenticate
  /// users. Clients should pick one of these and supply it as
  /// the type when logging in.
  ///
  static Future<dynamic> loginUserToken({
    String? protocol,
    String? homeserver,
    String type = MatrixAuthTypes.TOKEN,
    String? token,
    String? session,
    String? deviceId,
    String? deviceName,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/login';

    final Map body = {
      'type': type,
      'token': token,
      'trx_id': Random().nextInt(1 << 32),
      // "session": session,
    };

    if (deviceId != null) {
      body['device_id'] = deviceId;
    }

    if (deviceName != null) {
      body['initial_device_display_name'] = deviceName;
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Register New User
  ///
  /// inhibit_login automatically logs in the user after creation
  static Future<dynamic> registerEmail({
    String? protocol,
    String? homeserver,
    String? clientSecret,
    String? email,
    int? sendAttempt = 1,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/register/email/requestToken';

    final Map body = {
      'email': email,
      'client_secret': clientSecret,
      'send_attempt': sendAttempt,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /// Register New User
  ///
  /// inhibit_login automatically logs in the user after creation
  static Future<dynamic> registerUser({
    String? protocol = Values.DEFAULT_PROTOCOL,
    String? homeserver,
    String? username,
    String? password,
    String? session,
    String? authType,
    String? authValue,
    Map? authParams,
    String? deviceId,
    String? deviceName,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/register';

    Map body = {
      'type': MatrixAuthTypes.DUMMY,
    };

    // Set and configure params for auth types
    switch (authType) {
      case MatrixAuthTypes.RECAPTCHA:
        body = {
          'auth': {
            'type': MatrixAuthTypes.RECAPTCHA,
            'response': authValue,
          }
        };
        break;
      case MatrixAuthTypes.TERMS:
        body = {
          'auth': {
            'type': MatrixAuthTypes.TERMS,
          }
        };
        break;
      case MatrixAuthTypes.EMAIL:
        body = {
          'auth': {
            'type': MatrixAuthTypes.EMAIL,
            'threepid_creds': {
              'sid': authParams!['sid'],
              'client_secret': authParams['client_secret'],
            },
            'threepidCreds': {
              'sid': authParams['sid'],
              'client_secret': authParams['client_secret'],
            }
          }
        };
        break;
      case MatrixAuthTypes.DUMMY: // actually password auth, poor spec design
        body = {
          'username': username,
          'password': password,
          'inhibit_login': false,
          'auth': {
            'type': MatrixAuthTypes.DUMMY,
          }
        };
        break;
      default:
        break;
    }

    // Assign session if set
    if (session != null) {
      body['auth']['session'] = session;
    }

    if (deviceId != null) {
      body['initial_device_display_name'] = deviceName;
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> logoutUser({
    String? protocol,
    String? homeserver,
    String? accessToken,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/logout';

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

  /// Logout User Everywhere
  static Future<dynamic> logoutUserEverywhere({
    String? protocol,
    String? homeserver,
    String? accessToken,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/logout/all';

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

  ///  https://matrix.org/docs/spec/client_server/latest#id211
  ///
  ///  Check Username Availability
  ///
  ///  Used to check what types of logins are available on the server
  static Future<dynamic> checkUsernameAvailability({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
    String? username,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/register/available';

    url += username != null ? '?username=$username' : '';

    // Specified timeout because servers can hang
    final response = await httpClient.get(Uri.parse(url)).timeout(
      Duration(seconds: 5),
      onTimeout: () {
        // Time has run out, do what you wanted to do.
        return http.Response('Error', 500); // Replace 500 with your http code.
      },
    );

    return await json.decode(response.body);
  }

  ///  https://matrix.org/docs/spec/client_server/latest#id211
  ///
  ///  Check Username Availability
  ///
  ///  Used to check what types of logins are available on the server
  static Future<dynamic> checkHomeserver({
    String protocol = 'https://',
    String homeserver = Values.homeserverDefault,
  }) async {
    final String url = '$protocol$homeserver/.well-known/matrix/client';

    try {
      final response = await httpClient.get(Uri.parse(url));

      return await json.decode(response.body);
    } catch (error) {
      printError(error.toString());
      rethrow;
    }
  }

  ///  https://matrix.org/docs/spec/client_server/latest#id211
  ///
  ///  Check Username Availability
  ///
  ///  Used to check what types of logins are available on the server
  static Future<dynamic> checkHomeserverAlt({
    String protocol = 'https://',
    String homeserver = Values.homeserverDefault,
  }) async {
    final String url = '$protocol$homeserver/.well-known/matrix/server';

    final response = await httpClient.get(Uri.parse(url));

    return await json.decode(response.body);
  }

  static Future<dynamic> checkVersion({
    String? protocol = 'https://',
    String? homeserver = Values.homeserverDefault,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/versions';

    final response = await httpClient.get(Uri.parse(url));

    return await json.decode(response.body);
  }

  /// Update User Password
  ///
  /// https://matrix.org/docs/spec/client_server/latest#id198
  ///
  static Future<dynamic> updatePassword({
    String? protocol,
    String? homeserver,
    String? accessToken,
    String type = 'm.login.password',
    String? userId,
    String? session,
    String? password,
    String? currentPassword,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/account/password';

    final Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
      ...Values.defaultHeaders,
    };

    final Map body = {
      'new_password': password,
      'logout_devices': false,
    };

    // Assign session if set
    if (session != null) {
      body['auth'] = {
        'session': session,
        'type': MatrixAuthTypes.PASSWORD,
        'user': userId,
        'password': currentPassword,
      };
    }

    final response = await httpClient.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  ///
  /// Reset Password
  ///
  /// Actually reset the password after verification
  ///
  static Future<dynamic> resetPassword({
    String? protocol,
    String? homeserver,
    String? clientSecret,
    String? passwordNew,
    String? session,
    int sendAttempt = 1,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/account/password';

    final Map body = {
      'auth': {
        'type': 'm.login.email.identity',
        'threepid_creds': {
          'sid': session,
          'client_secret': clientSecret,
        },
        'threepidCreds': {
          'sid': session,
          'client_secret': clientSecret,
        }
      },
      'new_password': passwordNew
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  ///
  /// Verify Password Reset Email
  ///
  /// Returns a token to verify the password reset
  /// request for a specifed email address
  static Future<dynamic> sendPasswordResetEmail({
    String? protocol,
    String? homeserver,
    String? clientSecret,
    String? email,
    int sendAttempt = 1,
  }) async {
    final String url = '$protocol$homeserver/_matrix/client/r0/account/password/email/requestToken';

    final Map body = {
      'email': email,
      'client_secret': clientSecret,
      'send_attempt': sendAttempt,
    };

    final response = await httpClient.post(
      Uri.parse(url),
      headers: {...Values.defaultHeaders},
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}
