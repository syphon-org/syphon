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
 * GET login
 * Used to check what types of logins are available on the server
 * curl -XGET "http://192.168.1.2:8008/_matrix/client/r0/register/available?username=testing"
{
    "flows": [ 
        {
            "type": "m.login.password"
        }
    ]
}
 */
dynamic buildCheckRegisterAvailableRequest({String username}) {
  String url = '_matrix/client/r0/register/available?username=${username}';
  return {'url': url};
}

/**   
  curl -XPOST \
  -d '{ "identifier": { "type": "m.id.user", "user": "tester2" }, "type": "m.login.password", "password": "test1234!", "initial_device_display_name": "Tether Client" }' \
  "http://192.168.1.2:8008/_matrix/client/r0/login" 
 */
dynamic buildLoginUserRequest({
  String type,
  String username,
  String password,
}) {
  String url = '_matrix/client/r0/login';

  Map body = {
    "identifier": {"type": "m.id.user", "user": username},
    'type': type,
    'password': password,
    "initial_device_display_name": "${username}'s Tether Client",
  };

  return {'url': url, 'body': body};
}

/**  
 * LOGOUT
  curl -XPOST \
  "http://192.168.1.2:8008/_matrix/client/r0/logout?access_token=MDAxNGxvY2F0aW9uIGVyZS5pbwowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjJjaWQgdXNlcl9pZCA9IEB0ZXN0ZXIyOmVyZS5pbwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IFhhTF5CS3J5Klg1MUhoQFQKMDAyZnNpZ25hdHVyZSB0WCVnyVWKqDc4SE6VkJEezQMqNRkHnvm85MIAoLA4Owo" 
 */
dynamic buildLogoutUserRequest({String accessToken}) {
  String url = '_matrix/client/r0/logout/all?access_token=$accessToken';
  return {'url': url};
}

/**  
 * LOGOUT EVERYWHERE
  curl -XPOST \
  "http://192.168.1.2:8008/_matrix/client/r0/logout/all?\
  access_token=MDAxNGxvY2F0aW9uIGVyZS5pbwowMDEzaWRlbnRpZmllciBrZXkKMDAxMGNpZCBnZW4gPSAxCjAwMjJjaWQgdXNlcl9pZCA9IEB0ZXN0ZXIyOmVyZS5pbwowMDE2Y2lkIHR5cGUgPSBhY2Nlc3MKMDAyMWNpZCBub25jZSA9IG8wbXZXLnFuR35IYkB2fnYKMDAyZnNpZ25hdHVyZSDXj2vPmNP2ia0mxucJMfU1Woa8UYcES0nob0eXvyVPpQo" 
 */
dynamic buildLogoutUserAllRequest({String accessToken}) {
  String url = '_matrix/client/r0/logout/all?access_token=$accessToken';
  return {'url': url};
}

/**  
  curl -XPOST \
  -d '{ "access_token": "" }'  \
  "http://192.168.1.2:8008/_matrix/client/r0/register?kind=user" 
 */
dynamic buildRegisterUserRequest(
    {String username, String password, String type}) {
  String url = '_matrix/client/r0/register';

  Map body = {
    'auth': {'type': 'm.login.dummy'},
    'username': username,
    'password': password
  };
  return {'url': url, 'body': body};
}
