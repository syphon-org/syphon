

### User Creation

```dart
/**
 * 
 * https://matrix.org/docs/spec/client_server/latest#id204
 * 
 * 
 * Email Request (?)
 * https://matrix-client.matrix.org/_matrix/client/r0/register/email/requestToken
 * 
 * Request Token + SID
 * {"email":"syphon+testing@ere.io","client_secret":"MDWVwN79p5xIz7bgazVXvO8aabbVD0LN","send_attempt":1,"next_link":"https://app.element.io/#/register?client_secret=MDWVwN79p5xIz7bgazVXvO8aabbVD0LN&hs_url=https%3A%2F%2Fmatrix-client.matrix.org&is_url=https%3A%2F%2Fvector.im&session_id=yGElwHyWRFHwVkChpyWIJqMO"}
 * 
 * Response Token + SID
 * {"sid": "UTWiabjnSXWWTAPs"}
 * 
 * 
 * Send Terms (?)
 * {"username":"syphon2","password":"testing again to see","initial_device_display_name":"app.element.io (Chrome, macOS)","auth":{"session":"yGElwHyWRFHwVkChpyWIJqMO","type":"m.login.terms"},"inhibit_login":true}
 * 
 * Send Email Auth (?)
 * {"username":"syphon2","password":"testing again to see","initial_device_display_name":"app.element.io (Chrome, macOS)","auth":{"session":"yGElwHyWRFHwVkChpyWIJqMO","type":"m.login.email.identity","threepid_creds":{"sid":"UTWiabjnSXWWTAPs","client_secret":"MDWVwN79p5xIz7bgazVXvO8aabbVD0LN"},"threepidCreds":{"sid":"UTWiabjnSXWWTAPs","client_secret":"MDWVwN79p5xIz7bgazVXvO8aabbVD0LN"}},"inhibit_login":true}
 * 
 */
ThunkAction<AppState> createUser({enableErrors = false}) {}
```

```dart

// needed to test the recursive messaging 'catch-up'
if (true) {
  printError('[fromMessageEvents] *** ${this.name} *** ');
  print('[limited] now ${limited}, before ${this.limited}');
  print('[lastHash] now ${lastHash}, before ${this.lastHash}');
  print('[prevHash] now ${prevHash}');
}

```

```dart
 // original initStore function without much regar
 // for action types. Ideally, it would have none.
 Future<Store> initStore() async {
   // Configure redux persist instance
   final persistor = Persistor<AppState>(
     storage: MemoryStorage(),
     serializer: CacheSerializer(),
     throttleDuration: Duration(milliseconds: 4500),
     shouldSave: (Store<AppState> store, dynamic action) {
       switch (action.runtimeType) {
         case SetSyncing:
         case SetSynced:
           // debugPrint('[Redux Persist] cache skip');
           return false;
         default:
           // debugPrint('[Redux Persist] caching');
           return true;
       }
     },
   );

```