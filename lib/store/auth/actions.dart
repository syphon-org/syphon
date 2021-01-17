// Dart imports:
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:crypt/crypt.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:syphon/cache/index.dart';
import 'package:syphon/global/libs/jack/index.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/auth.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/notifications.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/global/strings.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/auth/homeserver/actions.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/actions.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/store/search/actions.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:uni_links/uni_links.dart';
import 'package:url_launcher/url_launcher.dart';
import '../user/model.dart';

// Store

final protocol = DotEnv().env['PROTOCOL'];

class SetLoading {
  final bool loading;
  SetLoading({this.loading});
}

class SetCreating {
  final bool creating;
  SetCreating({this.creating});
}

class SetUser {
  final User user;
  SetUser({this.user});
}

class SetHostname {
  final String hostname;
  SetHostname({this.hostname});
}

class SetHomeserver {
  final Homeserver homeserver;
  SetHomeserver({this.homeserver});
}

class SetUsername {
  final String username;
  SetUsername({this.username});
}

class SetUsernameValid {
  final bool valid;
  SetUsernameValid({this.valid});
}

class SetStopgap {
  final bool stopgap;
  SetStopgap({this.stopgap});
}

class SetPassword {
  final String password;
  SetPassword({this.password});
}

class SetPasswordCurrent {
  final String password;
  SetPasswordCurrent({this.password});
}

class SetPasswordConfirm {
  final String password;
  SetPasswordConfirm({this.password});
}

class SetPasswordValid {
  final bool valid;
  SetPasswordValid({this.valid});
}

class SetEmail {
  final String email;
  SetEmail({this.email});
}

class SetEmailValid {
  final bool valid;
  SetEmailValid({this.valid});
}

class SetEmailAvailability {
  final bool available;
  SetEmailAvailability({this.available});
}

class SetAgreement {
  final bool agreement;
  SetAgreement({this.agreement});
}

class SetCaptcha {
  final bool completed;
  SetCaptcha({this.completed});
}

class SetUsernameAvailability {
  final bool availability;
  SetUsernameAvailability({this.availability});
}

class SetAuthObserver {
  final StreamController authObserver;
  SetAuthObserver({this.authObserver});
}

class SetSession {
  final String session;
  SetSession({this.session});
}

class SetCompleted {
  final List<String> completed;
  SetCompleted({this.completed});
}

class SetCredential {
  final Credential credential;
  SetCredential({this.credential});
}

class SetVerificationNeeded {
  final bool needed;
  SetVerificationNeeded({this.needed});
}

class SetInteractiveAuths {
  final Map interactiveAuths;
  SetInteractiveAuths({this.interactiveAuths});
}

class ResetUser {}

class ResetOnboarding {}

class ResetAuthStore {}

StreamSubscription _sub;

ThunkAction<AppState> initDeepLinks() => (Store<AppState> store) async {
      try {
        _sub = getUriLinksStream().listen((Uri uri) {
          print('[streamUniLinks] ${uri}');
          final token = uri.queryParameters['loginToken'];
          if (store.state.authStore.user == null) {
            store.dispatch(loginUserSSO(token: token));
          }
        }, onError: (err) {
          print('[streamUniLinks] error ${err}');
        });
      } on PlatformException {
        addAlert(
          message:
              'Failed to SSO Login, please try again later or contact support',
        );
        // Handle exception by warning the user their action did not succeed
        // return?
      }
    };

ThunkAction<AppState> disposeDeepLinks() => (Store<AppState> store) async {
      try {
        _sub.cancel();
      } catch (error) {}
    };

Future<Null> disposeUniLinks() async {}

ThunkAction<AppState> startAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.authStore.authObserver != null) {
      throw 'Cannot call startAuthObserver with an existing instance';
    }

    store.dispatch(
      SetAuthObserver(authObserver: StreamController<User>.broadcast()),
    );

    final user = store.state.authStore.user;
    final Function onAuthStateChanged = (User user) async {
      if (user != null && user.accessToken != null) {
        await store.dispatch(fetchAuthUserProfile());

        // Run for new authed user without a proper sync
        if (store.state.syncStore.lastSince == null) {
          await store.dispatch(initialSync());
        }

        // init encryption for E2EE
        await store.dispatch(initKeyEncryption(user));

        // init notifications
        globalNotificationPluginInstance = await initNotifications(
          onSelectNotification: (String payload) {
            debugPrint('[onSelectNotification] payload');
          },
          onSaveToken: (token) {
            store.dispatch(setPusherDeviceToken(token));
          },
        );

        // start syncing for user
        store.dispatch(startSyncObserver());
      } else {
        await store.dispatch(stopSyncObserver());
        store.dispatch(ResetSync());
        store.dispatch(ResetRooms());
        store.dispatch(ResetUser());
        store.dispatch(ResetCrypto());
      }
    };

    // init current auth state and set auth state listener
    onAuthStateChanged(user);
    store.state.authStore.onAuthStateChanged.listen(onAuthStateChanged);
  };
}

ThunkAction<AppState> stopAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.authStore.authObserver != null) {
      store.state.authStore.authObserver.close();
      store.dispatch(SetAuthObserver(authObserver: null));
    }
  };
}

/**
 * Generate Device Id
 * 
 * Used in matrix to distinguish devices
 * for encryption and verification
 */
ThunkAction<AppState> generateDeviceId({String salt}) {
  return (Store<AppState> store) async {
    // Wait at least 2 seconds until you can attempt to login again
    // includes processing time by authenticating matrix server
    store.dispatch(SetStopgap(stopgap: true));

    // prevents people spamming the login if it were to fail repeatedly
    Timer(Duration(seconds: 2), () {
      store.dispatch(SetStopgap(stopgap: false));
    });

    final defaultId = Random.secure().nextInt(1 << 31).toString();
    var device = Device(
      deviceId: defaultId,
      displayName: Values.appDisplayName,
    );

    var deviceId;

    try {
      final deviceInfoPlugin = new DeviceInfoPlugin();

      // Find a unique value for the type of device
      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        deviceId = info.androidId;
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        deviceId = info.identifierForVendor;
      } else {
        deviceId = Random.secure().nextInt(1 << 31).toString();
      }

      // hash it
      final cryptHash = Crypt.sha256(deviceId, rounds: 1000, salt: salt).hash;

      // make it easier to read
      final deviceIdHash = cryptHash
          .toUpperCase()
          .replaceAll(RegExp(r'[^\w]'), '')
          .substring(0, 10);

      device = Device(
        deviceId: deviceIdHash,
        deviceIdPrivate: deviceId,
        displayName: Values.appDisplayName,
      );

      return device;
    } catch (error) {
      debugPrint('[generateDeviceId] $error');
      return device;
    }
  };
}

ThunkAction<AppState> loginUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    try {
      final username = store.state.authStore.username;

      final Device device = await store.dispatch(
        generateDeviceId(salt: username),
      );

      var homeserver = store.state.authStore.homeserver;

      try {
        homeserver = await store.dispatch(fetchBaseUrl(homeserver: homeserver));
      } catch (error) {/* still attempt login */}

      final data = await MatrixApi.loginUser(
        protocol: protocol,
        type: MatrixAuthTypes.PASSWORD,
        homeserver: homeserver.baseUrl,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        deviceId: device.deviceId,
        deviceName: device.displayName,
      );

      if (data['errcode'] == 'M_FORBIDDEN') {
        throw 'Invalid credentials, confirm and try again';
      }

      if (data['errcode'] != null) {
        throw data['error'];
      }

      await store.dispatch(SetUser(
        user: User.fromMatrix(data),
      ));

      store.state.authStore.authObserver.add(
        store.state.authStore.user,
      );

      store.dispatch(ResetOnboarding());
    } catch (error) {
      store.dispatch(addAlert(
        origin: "loginUser",
        message: error,
        error: error,
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> loginUserSSO({String token}) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    try {
      final homeserver = await store.dispatch(
        fetchBaseUrl(homeserver: store.state.authStore.homeserver),
      );

      if (token == null) {
        final ssoUrl = 'https://${homeserver.baseUrl}${Values.matrixSSOUrl}';

        if (await canLaunch(ssoUrl)) {
          return await launch(ssoUrl, forceSafariVC: false);
        } else {
          throw 'Could not launch ${ssoUrl}';
        }
      }

      final username = store.state.authStore.username;

      final Device device = await store.dispatch(
        generateDeviceId(salt: username),
      );

      final data = await MatrixApi.loginUserToken(
        protocol: protocol,
        type: MatrixAuthTypes.TOKEN,
        homeserver: homeserver.baseUrl,
        token: token,
        session: null,
        deviceId: device.deviceId,
        deviceName: device.displayName,
      );

      if (data['errcode'] == 'M_FORBIDDEN') {
        throw 'Invalid credentials, confirm and try again';
      }

      if (data['errcode'] != null) {
        throw data['error'];
      }

      await store.dispatch(SetUser(
        user: User.fromMatrix(data),
      ));

      store.state.authStore.authObserver.add(
        store.state.authStore.user,
      );

      store.dispatch(ResetOnboarding());
    } catch (error) {
      store.dispatch(addAlert(
        origin: "loginUser",
        message: error,
        error: error,
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> logoutUser() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      store.dispatch(stopSyncObserver());
      // submit empty auth before logging out of matrix

      if (store.state.authStore.user.homeserver == null) {
        throw Exception('Unavailable user data');
      }
      final temp = '${store.state.authStore.user.accessToken}';
      store.state.authStore.authObserver.add(null);

      final data = await MatrixApi.logoutUser(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: temp,
      );

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.unknown_token) {
          store.state.authStore.authObserver.add(null);
        } else {
          throw Exception(data['error']);
        }
      }

      // wipe cache
      await deleteCache();
      await initCache();

      // wipe cold storage
      await deleteStorage();
      await initStorage();

      // tell authObserver to wipe auth user
      store.state.authStore.authObserver.add(null);
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: error,
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchAuthUserProfile() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchUserProfile(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.currentUser.userId,
      );

      store.dispatch(SetUser(
        user: store.state.authStore.currentUser.copyWith(
          displayName: data['displayname'],
          avatarUri: data['avatar_url'],
        ),
      ));
    } catch (error) {
      store.dispatch(addAlert(
        error: error,
        message: 'Failed to fetch current user profile',
        origin: 'fetchAuthUserProfile',
      ));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> checkUsernameAvailability() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.checkUsernameAvailability(
        protocol: protocol,
        homeserver: store.state.authStore.hostname,
        username: store.state.authStore.username,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      store.dispatch(SetUsernameAvailability(
        availability: data['available'],
      ));
    } catch (error) {
      debugPrint('[checkUsernameAvailability] $error');
      store.dispatch(SetUsernameAvailability(availability: false));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> setInteractiveAuths({Map auths}) {
  return (Store<AppState> store) async {
    try {
      final List<String> completed =
          List<String>.from(auths['completed'] ?? []) ?? [];

      await store.dispatch(SetSession(session: auths['session']));
      await store.dispatch(SetCompleted(completed: completed));
      await store.dispatch(SetInteractiveAuths(interactiveAuths: auths));

      if (auths['flows'] != null && auths['flows'].length > 0) {
        // Set completed if certain flows exist
        final List<dynamic> stages = auths['flows'][0]['stages'];

        // Find next stage that needs to be completed
        final currentStage = stages.firstWhere(
          (stage) => !completed.contains(stage),
        );

        if (currentStage.length > 0) {
          debugPrint('[SetCredential] $currentStage');
          store.dispatch(SetCredential(
            credential: Credential(
              type: currentStage,
              params: auths['params'],
            ),
          ));
        }
      }
    } catch (error) {
      debugPrint('[setInteractiveAuth] $error');
    }
  };
}

ThunkAction<AppState> submitEmail({int sendAttempt = 1}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final emailSubmitted = store.state.authStore.email;
      final homeserver = store.state.authStore.hostname;
      final currentCredential = store.state.authStore.credential;

      if (currentCredential.params.containsValue(emailSubmitted) &&
          sendAttempt < 2) {
        return true;
      }

      final data = await MatrixApi.registerEmail(
        protocol: protocol,
        homeserver: homeserver,
        email: store.state.authStore.email,
        clientSecret: Values.clientSecretMatrix,
        sendAttempt: sendAttempt,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      store.dispatch(
        SetCredential(
          credential: currentCredential.copyWith(
            params: {
              'sid': data['sid'],
              'client_secret': Values.clientSecretMatrix,
              'email_submitted': store.state.authStore.email
            },
          ),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('[submitEmail] $error');
      store.dispatch(SetEmailValid(valid: false));
      store.dispatch(SetEmailAvailability(available: false));
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * 
 * Create a user / Attempt creation
 * 
 * process references are in assets/cheatsheet.md
 */
ThunkAction<AppState> createUser({enableErrors = false}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      store.dispatch(SetCreating(creating: true));

      final homeserver = store.state.authStore.homeserver.baseUrl;
      final loginType = store.state.authStore.homeserver.loginType;
      final credential = store.state.authStore.credential;
      final session = store.state.authStore.session;
      final authType = session != null ? credential.type : loginType;
      final authValue = session != null ? credential.value : null;
      final authParams = session != null ? credential.params : null;

      final device = await store.dispatch(generateDeviceId(
        salt: store.state.authStore.username,
      ));

      final data = await MatrixApi.registerUser(
        protocol: protocol,
        homeserver: homeserver,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        session: store.state.authStore.session,
        authType: authType,
        authValue: authValue,
        authParams: authParams,
        deviceId: device.deviceId,
        deviceName: device.displayName,
      );

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.not_authorized &&
            credential.type == MatrixAuthTypes.EMAIL) {
          store.dispatch(SetVerificationNeeded(needed: true));
          return false;
        }
        throw data['error'];
      }

      if (data['flows'] != null) {
        await store.dispatch(setInteractiveAuths(auths: data));

        final List<dynamic> stages =
            store.state.authStore.interactiveAuths['flows'][0]['stages'];
        final completed = store.state.authStore.completed;

        // Compare the completed stages to the flow stages provided
        final bool completedAll = stages.fold(true, (hasCompleted, stage) {
          return hasCompleted && completed.contains(stage);
        });

        return completedAll;
      }

      store.dispatch(SetUser(user: User.fromMatrix(data)));

      store.state.authStore.authObserver.add(
        store.state.authStore.user,
      );

      store.dispatch(ResetOnboarding());
      return true;
    } catch (error) {
      debugPrint('[createUser] error $error');
      if (enableErrors) {
        store.dispatch(
          addAlert(message: 'Failed to signup', error: error),
        );
      }
      return false;
    } finally {
      store.dispatch(SetCreating(creating: false));
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> updatePassword(String password) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      var data;

      // Call just to get interactive auths
      data = await MatrixApi.updatePassword(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        password: password,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      if (data['flows'] != null) {
        await store.dispatch(setInteractiveAuths(auths: data));

        data = await MatrixApi.updatePassword(
          protocol: protocol,
          homeserver: store.state.authStore.user.homeserver,
          accessToken: store.state.authStore.user.accessToken,
          userId: store.state.authStore.user.userId,
          session: store.state.authStore.session,
          password: password,
          currentPassword: store.state.authStore.passwordCurrent,
        );
      }

      if (data['errcode'] != null) {
        throw data['error'];
      }

      store.dispatch(addConfirmation(
        message: 'Password updated successfully',
      ));

      return true;
    } catch (error) {
      store.dispatch(addAlert(
        origin: 'updatePassword',
        message: 'Failed to update passwod',
        error: error,
      ));
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> updateDisplayName(String newDisplayName) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.updateDisplayName(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
        displayName: newDisplayName,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }
      return true;
    } catch (error) {
      store.dispatch(addAlert(origin: 'updateDisplayName', message: error));
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> updateAvatar({File localFile}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final String displayName = store.state.authStore.user.displayName;

      final data = await store.dispatch(uploadMedia(
        localFile: localFile,
        mediaName: '${displayName}_profile_photo',
      ));

      await store.dispatch(updateAvatarUri(
        mxcUri: data['content_uri'],
      ));

      return true;
    } catch (error) {
      store.dispatch(
        addAlert(origin: 'updateAvatar', message: error.error),
      );
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * updateAvatarUri
 * 
 * Helper action - no try catch as it's meant to be
 * included in other update actions
 */
ThunkAction<AppState> updateAvatarUri({String mxcUri}) {
  return (Store<AppState> store) async {
    final data = await MatrixApi.updateAvatarUri(
      protocol: protocol,
      homeserver: store.state.authStore.user.homeserver,
      accessToken: store.state.authStore.user.accessToken,
      userId: store.state.authStore.user.userId,
      avatarUri: mxcUri,
    );

    if (data['errcode'] != null) {
      throw data['error'];
    }
  };
}

ThunkAction<AppState> setLoading(bool loading) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: loading));
  };
}

/**
 * Update current interactive auth attempt
 */
ThunkAction<AppState> updateCredential({
  String type,
  String value,
  Map<String, String> params,
}) {
  return (Store<AppState> store) {
    try {
      final currentCredential = store.state.authStore.credential;
      store.dispatch(SetCredential(
        credential: currentCredential.copyWith(
          type: type,
          value: value,
          params: params,
        ),
      ));
    } catch (error) {
      debugPrint('[updateCredential] $error');
    }
  };
}

ThunkAction<AppState> resetCredentials({
  String type,
  String value,
  Map<String, String> params,
}) {
  return (Store<AppState> store) async {
    store.dispatch(SetSession(session: null));
    store.dispatch(SetCredential(
      credential: null,
    ));
  };
}

ThunkAction<AppState> selectHomeserver({String hostname}) {
  return (Store<AppState> store) async {
    final Homeserver homeserver = await store.dispatch(
      fetchHomeserver(hostname: hostname),
    );

    store.dispatch(setHomeserver(homeserver: homeserver));
    store.dispatch(setHostname(hostname: hostname));

    return homeserver.valid;
  };
}

ThunkAction<AppState> fetchHomeservers() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    final List<dynamic> homeserversJson = await JackApi.fetchPublicServers();

    // parse homeserver data
    final List<Homeserver> homserverData = homeserversJson.map((data) {
      final hostname = data['hostname'].toString().split('.');
      final hostnameBase = hostname.length > 1
          ? hostname[hostname.length - 2] + '.' + hostname[hostname.length - 1]
          : hostname[0];

      return Homeserver(
        hostname: hostnameBase,
        location: data['location'] ?? '',
        description: data['description'] ?? '',
        usersActive: data['users_active'] != null
            ? data['users_active'].toString()
            : null,
        roomsTotal: data['public_room_count'] != null
            ? data['public_room_count'].toString()
            : null,
        founded:
            data['online_since'] != null ? data['online_since'].toString() : '',
        responseTime: data['last_response_time'] != null
            ? data['last_response_time'].toString()
            : '',
      );
    }).toList();

    // set homeservers without cached photo url
    await store.dispatch(SetHomeservers(homeservers: homserverData));

    // find favicons for all the homeservers
    final homeservers = await Future.wait(
      homserverData.map((homeserver) async {
        final faviconUrl = await fetchFavicon(url: homeserver.hostname);
        try {
          final response = await http.get(faviconUrl);

          if (response.statusCode == 200) {
            return homeserver.copyWith(photoUrl: faviconUrl);
          }
        } catch (error) {/* noop */}

        return homeserver;
      }),
    );

    // set the homeservers and finish loading
    await store.dispatch(SetHomeservers(homeservers: homeservers));
    store.dispatch(SetLoading(loading: false));
  };
}

ThunkAction<AppState> fetchHomeserver({String hostname}) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));
    var homeserver = Homeserver(hostname: hostname);

    // fetch homeserver icon url
    try {
      final iconUrl = await fetchFavicon(url: homeserver.hostname);

      homeserver = homeserver.copyWith(photoUrl: iconUrl);
    } catch (error) {
      printError('[selectHomserver] $error');
    }

    // fetch homeserver well-known
    try {
      homeserver = await store.dispatch(fetchBaseUrl(homeserver: homeserver));
      if (!homeserver.valid) {
        throw Exception(Strings.errorCheckHomeserver);
      }
    } catch (error) {
      addInfo(message: error);

      store.dispatch(SetLoading(loading: false));

      return Homeserver(
        valid: true,
        hostname: hostname,
        baseUrl: hostname,
        loginType: MatrixAuthTypes.DUMMY,
      );
    }

    // fetch homeserver login type
    try {
      final response = await MatrixApi.loginType(
            protocol: protocol,
            homeserver: homeserver.baseUrl,
          ) ??
          {};

      // { "flows": [ { "type": "m.login.sso" }, { "type": "m.login.token" } ]}
      final loginType = (response['flows'] as List).elementAt(0)['type'];

      homeserver = homeserver.copyWith(loginType: loginType);
    } catch (error) {}

    store.dispatch(SetLoading(loading: false));
    return homeserver;
  };
}

ThunkAction<AppState> setHostname({String hostname}) =>
    (Store<AppState> store) {
      store.dispatch(SetHostname(hostname: hostname.trim()));
    };

ThunkAction<AppState> setHomeserver({Homeserver homeserver}) =>
    (Store<AppState> store) {
      store.dispatch(SetHomeserver(homeserver: homeserver));
    };

ThunkAction<AppState> setEmail({String email}) {
  return (Store<AppState> store) {
    final validEmail = RegExp(Values.emailRegex).hasMatch(email);

    store.dispatch(SetEmailValid(
      valid: email != null && email.length > 0 && validEmail,
    ));
    store.dispatch(SetEmail(email: email));
    store.dispatch(SetEmailAvailability(available: true));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username.trim()));
  };
}

ThunkAction<AppState> setLoginPassword({String password}) =>
    (Store<AppState> store) {
      store.dispatch(SetPassword(password: password));

      store.dispatch(SetPasswordValid(
        valid: password != null && password.length > 0,
      ));
    };

ThunkAction<AppState> setPassword({String password, bool ignoreConfirm}) {
  return (Store<AppState> store) {
    store.dispatch(SetPassword(password: password));

    final currentPassword = store.state.authStore.password;
    final currentConfirm = store.state.authStore.passwordConfirm;

    store.dispatch(SetPasswordValid(
      valid: password != null &&
          currentConfirm != null &&
          password.length > 6 &&
          (currentPassword == currentConfirm || ignoreConfirm),
    ));
  };
}

ThunkAction<AppState> setPasswordCurrent({String password}) {
  return (Store<AppState> store) {
    store.dispatch(SetPasswordCurrent(password: password));
  };
}

ThunkAction<AppState> setPasswordConfirm({String password}) {
  return (Store<AppState> store) {
    store.dispatch(SetPasswordConfirm(password: password));

    final currentPassword = store.state.authStore.password;
    final currentConfirm = store.state.authStore.passwordConfirm;

    store.dispatch(SetPasswordValid(
      valid: password != null &&
          password.length > 6 &&
          currentPassword == currentConfirm,
    ));
  };
}

ThunkAction<AppState> toggleAgreement({bool agreement}) {
  return (Store<AppState> store) {
    store.dispatch(SetAgreement(
      agreement: agreement ?? !store.state.authStore.agreement,
    ));
  };
}

ThunkAction<AppState> toggleCaptcha({bool completed}) {
  return (Store<AppState> store) async {
    store.dispatch(
      SetCaptcha(completed: completed ?? !store.state.authStore.captcha),
    );
  };
}
