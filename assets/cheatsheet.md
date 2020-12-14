

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

```dart
  // invite and membership events are different

  // {membership: join, displayname: usbfingers, avatar_url: mxc://matrix.org/RrRcMHnqXaJshyXZpGrZloyh }
  // {is_direct: true, membership: invite, displayname: ereio, avatar_url: mxc://matrix.org/JllILpqzdFAUOvrTPSkDryzW}

```

```dart

/** 
 * OneTimeKey Data Model
 * 
 * https://matrix.org/docs/spec/client_server/latest#id468
 * {
  "failures": {},
    "one_time_keys": {
      "@alice:example.com": {
        "JLAFKJWSCS": {
          "signed_curve25519:AAAAHg": {
            "key": "zKbLg+NrIjpnagy+pIY6uPL4ZwEG2v+8F9lmgsnlZzs",
            "signatures": {
              "@alice:example.com": {
                "ed25519:JLAFKJWSCS": "FLWxXqGbwrb8SM3Y795eB6OA8bwBcoMZFXBqnTn58AYWZSqiD45tlBVcDa2L7RwdKXebW/VzDlnfVJ+9jok1Bw"
              }
            }
          }
        }
      }
    }
  }
 */
 ```


 ```dart
/*
  Opening storage path on mobile devices (main thread only)
*/
 Future<dynamic> initStorageLocation() async {
  var storageLocation;

  try {
    if (Platform.isIOS || Platform.isAndroid) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    if (Platform.isMacOS) {
      storageLocation = await File('cache').create().then(
            (value) => value.writeAsString(
              '{}',
              flush: true,
            ),
          );

      return storageLocation.path;
    }

    if (Platform.isLinux) {
      storageLocation = await getApplicationDocumentsDirectory();
      return storageLocation.path;
    }

    debugPrint('[initStorageLocation] no cache support');
    return null;
  } catch (error) {
    debugPrint('[initStorageLocation] $error');
    return null;
  }
}

```

```dart
 // reduce several maps to one map
 final allDirectUsers = roomsDirectUsers.fold(
   {},
   (usersAll, users) {
     (usersAll as Map).addAll(users);
     return usersAll;
   },
 );
  
  ```