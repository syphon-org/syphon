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
  -d '{"type":"m.login.password", "user":"example", "password":"wordpass"}' \
  "http://192.168.1.2:8008/_matrix/client/r0/login"
{
    "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.vRDLTgxefmKWQEtgGd", 
    "home_server": "192.168.1.2", 
    "user_id": "@example:192.168.1.2"
}
 */
dynamic buildLoginUserRequest({String username, String password, String type}) {
  String url = '_matrix/client/r0/login';

  Map body = {'type': type, 'user': username, 'password': password};

  return {'url': url, 'body': body};
}

/**  
  curl -XPOST \
  -d '{ "auth": {"type":"m.login.dummy"}, "username":"testing", "password":"test1234!" }'  \
  "http://192.168.1.2:8008/_matrix/client/r0/register?kind=user" 

  curl -XPOST \
  -d '{  "auth": {"type":"m.login.password"}}'  \
  "http://192.168.1.2:8008/_matrix/client/r0/register?kind=user" 
{
    "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.AqdSzFmFYrLrTmteXc", 
    "home_server": "192.168.1.2", 
    "user_id": "@example:192.168.1.2"
}
 */
dynamic buildRegisterUserRequest(
    {String username, String password, String type}) {
  String url = '_matrix/client/r0/register';

  Map body = {
    'auth': {'type': 'm.login.dummy'},
    'user': username,
    'password': password
  };
  return {'url': url, 'body': body};
}
