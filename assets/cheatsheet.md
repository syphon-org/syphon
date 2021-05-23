
### Pain Points
 
 - Plugins should be able to run in isolates without additional hackery
 - still having issues using path_provider or any equivalent in threads while still being able to pass the entire store object to the isolate

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
      storageLocation = await getApplicationSupportDirectory();
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
      storageLocation = await getApplicationSupportDirectory();
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


### captcha
flutter_recaptcha_v2: 0.1.0 used as reference for webview captcha


```dart 
 Future<String> get _localPath async {
   final directory = await getApplicationDocumentsDirectory();
   return directory.path;
 }

 Future<File> get _localFile async {
   final path = await _localPath;
   return File('$path/matrix.json');
 }

 Future<dynamic> readFullSyncJson() async {
   try {
     final file = await _localFile;
     String contents = await file.readAsString();
     return await jsonDecode(contents);
   } catch (error) {
     // If encountering an error, return 0.
     debugPrint('[readFullSyncJson] $error');
     return null;
   } finally {
     debugPrint('** Read State From Disk Successfully **');
   }
 }
```


```dart

  /// something to try when binding state, the downside is you
  /// don't get the didUpdateWidget
  class ChatViewConnected extends StatelessWidget {
    @override
    Widget build(BuildContext context) => StoreConnector<AppState, _Props>(
          distinct: true,
          converter: (Store<AppState> store) => _Props.mapStateToProps(
            store,
            (ModalRoute.of(context).settings.arguments as ChatViewArguements)
                .roomId,
          ),
          builder: (context, props) {
            return ChatView();
          },
        );
 }
```

```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final store = StoreProvider.of<AppState>(context);
    final props = _Props.mapStateToProps(store);

    switch (state) {
      case AppLifecycleState.resumed:
        if (success == null || !success) {
          final result = await props.onCreateUser(enableErrors: true);
          this.setState(() {
            success = result;
          });
        }
        break;
      case AppLifecycleState.inactive:
        debugPrint("app in inactive");
        break;
      case AppLifecycleState.paused:
        debugPrint("app in paused");
        break;
      case AppLifecycleState.detached:
        debugPrint("app in detached");
        break;
    }
  }
```


```dart
// TODO: refactor sync device and/or use this one?
ThunkAction<AppState> syncDeviceNew(Map dataToDevice) {
  return (Store<AppState> store) async {
    try {
      // Extract the new events
      final List<dynamic> events = dataToDevice['events'];

      // Parse and decrypt necessary events
      for (final event in events) {
        final eventType = event['type'];
        final identityKeySender = event['content']['sender_key'];

        switch (eventType) {
          case EventTypes.encrypted:
            final eventDecrypted = await store.dispatch(
              decryptKeyEvent(event: event),
            );

            if (EventTypes.roomKey == eventDecrypted['type']) {
              await store.dispatch(
                saveSessionKey(
                  event: eventDecrypted,
                  identityKey: identityKeySender,
                ),
              );
            }
            break;
          default:
            break;
        }
      }
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        origin: 'syncDevice',
      ));
    }
  };
}
```