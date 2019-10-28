/** 
 * GET login
 * Used to check what types of logins are available on the server
 * curl -XGET "https://localhost:8448/_matrix/client/r0/login"
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
  return {url: url};
}

/**  
 * curl -XPOST 
 * -d '{"type":"m.login.password", "user":"example", "password":"wordpass"}' 
 * "https://localhost:8448/_matrix/client/r0/login"
{
    "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.vRDLTgxefmKWQEtgGd", 
    "home_server": "localhost", 
    "user_id": "@example:localhost"
}
 */
dynamic buildLoginUserRequest(
    {String homeserver, String username, String password, String type}) {
  var url = "https://${homeserver}/_matrix/client/r0/login";
  var requestData = {
    "url": url,
    "body": {"type": type, "user": username, "password": password}
  };
  return {url: url, requestData: requestData};
}

/**  
 * curl -XPOST 
 * -d '{"username":"example", "password":"wordpass", "auth": {"type":"m.login.dummy"}}' 
 * "https://localhost:8448/_matrix/client/r0/register"
{
    "access_token": "QGV4YW1wbGU6bG9jYWxob3N0.AqdSzFmFYrLrTmteXc", 
    "home_server": "localhost", 
    "user_id": "@example:localhost"
}
 */
dynamic buildRegisterUserRequest(
    {String homeserver, String username, String password, String type}) {
  var url = "https://${homeserver}/_matrix/client/r0/register";

  var requestData = {
    "url": url,
    "body": {
      "auth": {"type": type},
      "user": username,
      "password": password
    }
  };
  return {url: url, requestData: requestData};
}
