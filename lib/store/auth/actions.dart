import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:Tether/global/libs/matrix/errors.dart';
import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/store/auth/credential/model.dart';
import 'package:Tether/store/settings/devices-settings/model.dart';
import 'package:Tether/store/sync/actions.dart';
import 'package:device_info/device_info.dart';
import 'package:mime/mime.dart';
import 'package:crypt/crypt.dart';

import 'package:Tether/global/libs/matrix/media.dart';
import 'package:Tether/store/rooms/actions.dart';
import 'package:Tether/global/notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Store
import 'package:Tether/store/index.dart';
import 'package:Tether/store/alerts/actions.dart';
import 'package:Tether/global/libs/matrix/user.dart';
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

class SetPasswordConfirm {
  final String password;
  SetPasswordConfirm({this.password});
}

class SetPasswordValid {
  final bool valid;
  SetPasswordValid({this.valid});
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
      throw 'Cannot call startAuthObserver with an existing instance!';
    }

    store.dispatch(
      SetAuthObserver(authObserver: StreamController<User>.broadcast()),
    );

    final user = store.state.authStore.user;
    final Function onAuthStateChanged = (user) async {
      if (user != null && user.accessToken != null) {
        await store.dispatch(fetchUserProfile());

        // Run for new authed user without a proper sync
        if (store.state.syncStore.lastSince == null) {
          await store.dispatch(initialSync());
        }

        globalNotificationPluginInstance = await initNotifications(
          onSelectNotification: (String payload) {
            print('[onSelectNotification] payload');
          },
        );
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

ThunkAction<AppState> generateHashedDeviceId({String salt}) {
  return (Store<AppState> store) async {
    final defaultId = Random.secure().nextInt(1 << 31).toString();
    var device = Device(
      deviceId: defaultId,
      displayName: 'Default Tim Client',
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
          displayName: 'Tim Android',
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
          displayName: 'Tim iOS',
        );
      } else if (Platform.isMacOS) {
        device = Device(
          deviceId: defaultId,
          displayName: 'Tim Desktop',
        );
      }
      return device;
    } catch (error) {
      print(
        '[loginUser] failed to parse unique secure device identifier $error',
      );
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
        generateHashedDeviceId(salt: username),
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

      print(data);

      await store.dispatch(SetUser(
        user: User.fromJson(data),
      ));

      store.state.authStore.authObserver.add(
        store.state.authStore.user,
      );

      store.dispatch(ResetOnboarding());
    } catch (error) {
      print(error);
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

      final request = buildUserProfileRequest(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.currentUser.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      store.dispatch(SetUser(
        user: store.state.authStore.currentUser.copyWith(
          displayName: data['displayname'],
          avatarUri: data['avatar_url'],
        ),
      ));
    } catch (error) {
      print('[fetchUserProfile] $error');
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
      print('[checkUsernameAvailability] $error');
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
        print('stages $stages');

        final currentStage = stages.firstWhere(
          (stage) => !completed.contains(stage),
        );

        if (currentStage.length > 0) {
          store.dispatch(SetCredential(
            credential: Credential(
              type: currentStage,
              params: auths['params'],
            ),
          ));
        }
      }
    } catch (error) {
      store.dispatch(SetSession(session: null));
      print('[setInteractiveAuth] $error');
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

      final device = await store.dispatch(generateHashedDeviceId(
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

      print('[createUser] $data');

      if (data['errcode'] != null) {
        throw data['error'];
      }

      if (data['flows'] != null) {
        await store.dispatch(setInteractiveAuths(auths: data));

        final List<dynamic> flows =
            store.state.authStore.interactiveAuths['flows'];
        final completed = store.state.authStore.completed;

        final bool hasCompleted = flows.reduce((hasCompleted, flow) {
          print('[creatUser] flow $flow');
          return hasCompleted ||
              (flow['stages'] as List<dynamic>).every(
                (stage) => completed.contains(stage),
              );
        });

        return hasCompleted;
      }

      store.dispatch(SetUser(
        user: User.fromJson(data),
      ));

      store.dispatch(ResetOnboarding());
      return true;
    } catch (error) {
      print('[createUser] $error');
      return false;
    } finally {
      store.dispatch(SetCreating(creating: false));
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> updateDisplayName(String newDisplayName) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final request = buildUpdateDisplayName(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        userId: store.state.authStore.user.userId,
        newDisplayName: newDisplayName,
      );

      final response = await http.put(
        request['url'],
        headers: request['headers'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);

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
    final avatarUriRequest = buildUpdateAvatarUri(
      protocol: protocol,
      homeserver: store.state.authStore.user.homeserver,
      accessToken: store.state.authStore.user.accessToken,
      userId: store.state.authStore.user.userId,
      newAvatarUri: mxcUri,
    );

    final avatarUriResponse = await http.put(
      avatarUriRequest['url'],
      headers: avatarUriRequest['headers'],
      body: json.encode(avatarUriRequest['body']),
    );

    final avatarUriData = json.decode(avatarUriResponse.body);

    if (avatarUriData['errcode'] != null) {
      throw avatarUriData['error'];
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
      print('[updateCredential] $error');
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
        SetHomeserverValid(valid: homeserver != null && homeserver.length > 0));
    store.dispatch(SetHomeserver(homeserver: homeserver.trim()));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username.trim()));
  };
}

ThunkAction<AppState> setPassword({String password}) {
  return (Store<AppState> store) {
    store.dispatch(SetPassword(password: password.trim()));
    store.dispatch(SetPasswordValid(
      valid: password != null && password.length > 0,
    ));
  };
}

ThunkAction<AppState> setPasswordConfirm({String password}) {
  return (Store<AppState> store) {
    store.dispatch(SetPasswordConfirm(password: password.trim()));

    final currentPassword = store.state.authStore.password;
    final currentConfirm = store.state.authStore.passwordConfirm;

    store.dispatch(SetPasswordValid(
      valid: password != null &&
          password.length > 0 &&
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
