import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:syphon/global/algos.dart';
import 'package:syphon/global/libs/matrix/errors.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/values.dart';
import 'package:syphon/store/auth/credential/model.dart';
import 'package:syphon/store/crypto/actions.dart';
import 'package:syphon/store/settings/devices-settings/model.dart';
import 'package:syphon/store/settings/notification-settings/actions.dart';
import 'package:syphon/store/sync/actions.dart';
import 'package:device_info/device_info.dart';
import 'package:mime/mime.dart';
import 'package:crypt/crypt.dart';

import 'package:syphon/global/libs/matrix/media.dart';
import 'package:syphon/store/rooms/actions.dart';
import 'package:syphon/global/notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Store
import 'package:syphon/store/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import '../user/model.dart';

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

class SetHomeserver {
  final dynamic homeserver;
  SetHomeserver({this.homeserver});
}

class SetHomeserverValid {
  final bool valid;
  SetHomeserverValid({this.valid});
}

class SetUsername {
  final String username;
  SetUsername({this.username});
}

class SetUsernameValid {
  final bool valid;
  SetUsernameValid({this.valid});
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

class SetInteractiveAuths {
  final Map interactiveAuths;
  SetInteractiveAuths({this.interactiveAuths});
}

class ResetUser {}

class ResetOnboarding {}

class ResetAuthStore {}

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
        await store.dispatch(fetchUserProfile());

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
 * 
 */
ThunkAction<AppState> generateDeviceId({String salt}) {
  return (Store<AppState> store) async {
    final defaultId = Random.secure().nextInt(1 << 31).toString();
    var device = Device(
      deviceId: defaultId,
      displayName: Values.appDisplayName,
    );

    try {
      final deviceInfoPlugin = new DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final info = await deviceInfoPlugin.androidInfo;
        final deviceIdentifier = info.androidId;
        final hashedDeviceId = Crypt.sha256(
          deviceIdentifier,
          rounds: 1000,
          salt: salt,
        );

        device = Device(
          deviceId: hashedDeviceId.hash,
          deviceIdPrivate: info.androidId,
          displayName: Values.appDisplayName,
        );
      } else if (Platform.isIOS) {
        final info = await deviceInfoPlugin.iosInfo;
        final deviceIdentifier = info.identifierForVendor;

        final hashedDeviceId = Crypt.sha256(
          deviceIdentifier,
          rounds: 1000,
          salt: salt,
        );

        device = Device(
          deviceId: hashedDeviceId.hash,
          deviceIdPrivate: info.identifierForVendor,
          displayName: Values.appDisplayName,
        );
      } else if (Platform.isMacOS) {
        device = Device(
          deviceId: defaultId,
          displayName: Values.appDisplayName,
        );
      }
      return device;
    } catch (error) {
      debugPrint('[loginUser] $error');
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

      final data = await MatrixApi.loginUser(
        protocol: protocol,
        type: "m.login.password",
        homeserver: store.state.authStore.homeserver,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        deviceName: device.displayName,
        deviceId: device.deviceId,
      );

      if (data['errcode'] == 'M_FORBIDDEN') {
        throw 'Invalid credentials, confirm and try again';
      }

      if (data['errcode'] != null) {
        throw data['error'];
      }

      await store.dispatch(SetUser(
        user: User.fromJson(data),
      ));

      store.state.authStore.authObserver.add(
        store.state.authStore.user,
      );

      store.dispatch(ResetOnboarding());
    } catch (error) {
      debugPrint('[loginUser] $error');
      store.dispatch(addAlert(type: 'warning', message: error));
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

      final data = await MatrixApi.logoutUser(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        if (data['errcode'] == MatrixErrors.unknown_token) {
          store.state.authStore.authObserver.add(null);
        } else {
          throw Exception(data['error']);
        }
      }

      store.state.authStore.authObserver.add(null);
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error.message));
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchUserProfile() {
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
      debugPrint('[fetchUserProfile] $error');
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
        homeserver: store.state.authStore.homeserver,
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

      await store.dispatch(SetCompleted(completed: completed));
      await store.dispatch(SetSession(session: auths['session']));
      await store.dispatch(SetInteractiveAuths(interactiveAuths: auths));

      if (auths['flows'] != null && auths['flows'].length > 0) {
        // Set completed if certain flows exist
        final List<dynamic> stages = auths['flows'][0]['stages'];

        // Find next stage that needs to be completed
        final currentStage = stages.firstWhere(
          (stage) => !completed.contains(stage),
        );

        print('[currentStage check] ${currentStage.length > 0}');
        if (currentStage.length > 0) {
          print('[SetCredential] $currentStage');
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

/**
 * 
 * https://matrix.org/docs/spec/client_server/latest#id204
 */
ThunkAction<AppState> createUser() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      store.dispatch(SetCreating(creating: true));

      final loginType = store.state.authStore.loginType;
      final credential = store.state.authStore.credential;
      final session = store.state.authStore.session;
      final authType = session != null ? credential.type : loginType;
      final authValue = session != null ? credential.value : null;

      final device = await store.dispatch(generateDeviceId(
        salt: store.state.authStore.username,
      ));

      final data = await MatrixApi.registerUser(
        protocol: protocol,
        homeserver: store.state.authStore.homeserver,
        username: store.state.authStore.username,
        password: store.state.authStore.password,
        session: store.state.authStore.session,
        authType: authType,
        authValue: authValue,
        deviceId: device.deviceId,
        deviceName: device.displayName,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      if (data['flows'] != null) {
        await store.dispatch(setInteractiveAuths(auths: data));

        final List<dynamic> stages =
            store.state.authStore.interactiveAuths['flows'][0]['stages'];
        final completed = store.state.authStore.completed;

        debugPrint('[createUser] $stages $completed');

        // Compare the completed stages to the flow stages provided
        final bool completedAll = stages.fold(true, (hasCompleted, stage) {
          return hasCompleted && completed.contains(stage);
        });

        return completedAll;
      }

      store.dispatch(SetUser(
        user: User.fromJson(data),
      ));

      store.dispatch(ResetOnboarding());
      return true;
    } catch (error) {
      debugPrint('[createUser] $error');
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

      store.dispatch(addAlert(
        type: 'success',
        message: 'Password updated successfully',
      ));

      return true;
    } catch (error) {
      store.dispatch(addAlert(
        type: 'warning',
        message: error,
        origin: 'updatePassword',
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
      store.dispatch(addAlert(type: 'warning', message: error));
      return false;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> updateAvatarPhoto({File localFile}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // Extension handling
      final String displayName = store.state.authStore.user.displayName;
      final String fileType = lookupMimeType(localFile.path);
      final String fileExtension = fileType.split('/')[1];

      // Setting up params for upload
      final int fileLength = await localFile.length();
      final Stream<List<int>> fileStream = localFile.openRead();
      final String fileName = '${displayName}_profile_photo.${fileExtension}';

      // Create request vars for upload
      final mediaUploadRequest = buildMediaUploadRequest(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        fileName: fileName,
        fileType: fileType,
        fileLength: fileLength,
      );

      // POST StreamedRequest for uploading byteStream
      final request = new http.StreamedRequest(
        'POST',
        Uri.parse(mediaUploadRequest['url']),
      );
      request.headers.addAll(mediaUploadRequest['headers']);
      fileStream.listen(request.sink.add, onDone: () => request.sink.close());

      // Attempting to await the upload response successfully
      final mediaUploadResponseStream = await request.send();
      final mediaUploadResponse = await http.Response.fromStream(
        mediaUploadResponseStream,
      );
      final mediaUploadData = json.decode(
        mediaUploadResponse.body,
      );

      // If upload fails, throw an error for the whole update
      if (mediaUploadData['errcode'] != null) {
        throw mediaUploadData['error'];
      }

      await store.dispatch(updateAvatarUri(
        mxcUri: mediaUploadData['content_uri'],
      ));

      return true;
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error));
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
 * Fetch Active Devices for account
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

ThunkAction<AppState> selectHomeserver({dynamic homeserver}) {
  return (Store<AppState> store) {
    store.dispatch(SetHomeserverValid(valid: true));
    store.dispatch(SetHomeserver(homeserver: homeserver['hostname']));
  };
}

ThunkAction<AppState> setHomeserver({String homeserver}) {
  return (Store<AppState> store) {
    store.dispatch(
      SetHomeserverValid(valid: homeserver != null && homeserver.length > 0),
    );

    store.dispatch(
      SetHomeserver(homeserver: homeserver.trim()),
    );
  };
}

ThunkAction<AppState> setEmail({String email}) {
  return (Store<AppState> store) {
    final validEmail = RegExp(Values.emailRegex).hasMatch(email);

    debugPrint('$email $validEmail');

    store.dispatch(SetEmailValid(
      valid: email != null && email.length > 0 && validEmail,
    ));
    store.dispatch(SetEmail(email: email));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username.trim()));
  };
}

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
