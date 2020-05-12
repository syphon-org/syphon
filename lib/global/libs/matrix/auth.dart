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
  static const DUMMY = 'm.login.dummy';
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
  static Future<dynamic> loginUser({
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
      "initial_device_display_name": "$username's $deviceName Client",
    };

    final response = await http.post(
      url,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }

  static FutureOr<dynamic> registerUser({
    String protocol,
    String homeserver,
    String username,
    String password,
    String type,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/register';

    Map body = {
      'auth': {
        'type': 'm.login.dummy',
      },
      'username': username,
      'password': password
    };

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
   * https://matrix.org/docs/spec/client_server/latest#id198
   * 
   * Change User Password
   *  
   */
  static FutureOr<dynamic> changePassword({
    String protocol,
    String homeserver,
    String accessToken,
    String type = "m.login.password",
    String newPassword,
  }) async {
    String url = '$protocol$homeserver/_matrix/client/r0/account/password';

    Map<String, String> headers = {
      'Authorization': 'Bearer $accessToken',
    };

    Map body = {
      'new_password': type,
    };

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(body),
    );

    return await json.decode(response.body);
  }
}

/** 
 * GET login
 * Used to check what types of logins are available on the server
 * curl -XGET "http://192.168.1.2:8008/_matrix/client/r0/login"
{
    "flows": [ 
        {
            "type": "m.login.password"
        }
    ]
}
 */
dynamic buildLoginTypesRequest() {
  String url = '_matrix/client/r0/login';
  return {'url': url};
}

/**  
 * LOGOUT EVERYWHERE
  curl -XPOST \
  "http://192.168.1.2:8008/_matrix/client/r0/logout/all?\
  access_token=MDAxNGxvY2F0aW9uIGVyZS5pbwowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjJjaWQgdXNlcl9pZCA9IEB0ZXN0ZXIyOmVyZS5pbwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IG8wbXZXLnFuR35IYkB2fnYKMDAyZnNpZ25hdHVyZSDXj2vPmNP2ia0mxucJMfU1Woa8UYcES0nob0eXvyVPpQo" 
 */
dynamic buildLogoutUserAllRequest({String accessToken}) {
  String url = '_matrix/client/r0/logout/all';
  Map<String, String> headers = {'Authorization': 'Bearer $accessToken'};
  return {'url': url, 'headers': headers};
}

/**  
  curl -XPOST \
  -d '{ "access_token": "" }'  \
  "http://192.168.1.2:8008/_matrix/client/r0/register?kind=user" 
 */
dynamic buildRegisterUserRequest({
  String protocol,
  String homeserver,
  String username,
  String password,
  String type,
}) {
  String url = '$protocol$homeserver/_matrix/client/r0/register';

  Map body = {
    'auth': {'type': 'm.login.dummy'},
    'username': username,
    'password': password
  };
  return {'url': url, 'body': body};
}

/**
 * {
  "flows": [
    {
      "stages": [
        "example.type.foo"
      ]
    }
  ],
  "params": {
    "example.type.baz": {
      "example_key": "foobar"
    }
  },
  "session": "xxxxxxyz",
  "completed": [
    "example.type.foo"
  ]
}
 */
dynamic buildAuthenticationRequestWrapper() {}
