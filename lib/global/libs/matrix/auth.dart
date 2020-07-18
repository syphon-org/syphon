import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/**
 * https://matrix.org/docs/spec/client_server/latest#id183
 * 
 * Authentication Types
 * 
 * Can be used during actual login or interactive auth for confirmation
 */
class MatrixAuthTypes {
  static const PASSWORD = 'm.login.password';
  static const RECAPTCHA = 'm.login.recaptcha';
  static const TOKEN = 'm.login.token';
  static const TERMS = 'm.login.terms';
  static const DUMMY = 'm.login.dummy';
  static const EMAIL = 'm.login.email.identity';
}

abstract class Auth {
  static const NEEDS_INTERACTIVE_AUTH = 'needs_interactive_auth';
  /**
   * https://matrix.org/docs/spec/client_server/latest#id198
   * 
   * Login User
   * 
   *  Gets the homeserver's supported login types to authenticate
   *  users. Clients should pick one of these and supply it as 
   *  the type when logging in.
   */
  static FutureOr<dynamic> loginUser({
    String protocol,
    String homeserver,
    String type = "m.login.password",
    String username,
    String password,
    String deviceName,
    String deviceId,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/login';

    Map body = {
      'type': type,
      "identifier": {"type": "m.id.user", "user": username},
      'password': password,
      'device_id': deviceId,
      "initial_device_display_name": "$username's $deviceName",
    };

    final response = await http.post(
      url,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  /**
   * Register New User
   * 
   * inhibit_login automatically logs in the user after creation 
   */
  static FutureOr<dynamic> registerUser({
    String protocol,
    String homeserver,
    String username,
    String password,
    String session,
    String authType = MatrixAuthTypes.DUMMY,
    String authValue,
    String deviceId,
    String deviceName,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/register';

    Map body = {
      'username': username,
      'password': password,
      'inhibit_login': false,
      'auth': {
        'type': MatrixAuthTypes.DUMMY,
      }
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
      case MatrixAuthTypes.DUMMY: // default
      default:
        break;
    }

    // Assign session if set
    if (session != null) {
      body['auth']['session'] = session;
    }

    if (deviceId != null) {
      body['initial_device_display_name'] = "$username's $deviceName";
    }

    final response = await http.post(
      url,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  static Future<dynamic> logoutUser({
    String protocol,
    String homeserver,
    String accessToken,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/logout';

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
   * Logout User Everywhere
   */
  static Future<dynamic> logoutUserEverywhere({
    String protocol,
    String homeserver,
    String accessToken,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/logout/all';

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
   *  https://matrix.org/docs/spec/client_server/latest#id211 
   * 
   *  Check Username Availability
   * 
   *  Used to check what types of logins are available on the server
   */
  static Future<dynamic> checkUsernameAvailability({
    String protocol = 'https://',
    String homeserver = 'matrix.org',
    String username,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/register/available';

    url += username != null ? '?username=$username' : '';

    final response = await http.get(url);

    return await json.decode(response.body);
  }

  /**
   * Update User Password
   * 
   * https://matrix.org/docs/spec/client_server/latest#id198
   * 
   */
  static FutureOr<dynamic> updatePassword({
    String protocol,
    String homeserver,
    String accessToken,
    String type = 'm.login.password',
    String userId,
    String session,
    String password,
    String currentPassword,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/account/password';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
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

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}
