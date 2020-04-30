import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;

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
import 'package:Tether/global/libs/matrix/auth.dart';
import 'package:Tether/global/libs/matrix/user.dart';
import './model.dart';

const HOMESERVER_SEARCH_SERVICE =
    'https://www.hello-matrix.net/public_servers.php?format=json&only_public=true';

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

class SetPasswordValid {
  final bool valid;
  SetPasswordValid({this.valid});
}

class SetUsernameAvailability {
  final bool availability;
  SetUsernameAvailability({this.availability});
}

class SetAuthObserver {
  final StreamController authObserver;
  SetAuthObserver({this.authObserver});
}

class ResetOnboarding {}

class ResetUser {}

ThunkAction<AppState> startAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.userStore.authObserver != null) {
      throw 'Cannot call startAuthObserver with an existing instance!';
    }

    store.dispatch(
      SetAuthObserver(authObserver: StreamController<User>.broadcast()),
    );

    final user = store.state.userStore.user;
    final Function onAuthStateChanged = (user) async {
      if (user != null && user.accessToken != null) {
        await store.dispatch(fetchUserProfile());

        // Run for new authed user without a proper sync
        if (store.state.roomStore.lastSince == null) {
          await store.dispatch(initialRoomSync());
        }

        globalNotificationPluginInstance = await initNotifications(
          onSelectNotification: (String payload) {
            print('[onSelectNotification] payload');
          },
        );
        store.dispatch(startRoomsObserver());
      } else {
        store.dispatch(stopRoomsObserver());
      }
    };

    // init current auth state and set auth state listener
    onAuthStateChanged(user);
    store.state.userStore.onAuthStateChanged.listen(onAuthStateChanged);
  };
}

ThunkAction<AppState> stopAuthObserver() {
  return (Store<AppState> store) async {
    if (store.state.userStore.authObserver != null) {
      store.state.userStore.authObserver.close();
      store.dispatch(SetAuthObserver(authObserver: null));
    }
  };
}

ThunkAction<AppState> loginUser() {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: true));

    try {
      final authObserver = store.state.userStore.authObserver;

      final request = buildLoginUserRequest(
        type: "m.login.password",
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        username: store.state.userStore.username,
        password: store.state.userStore.password,
      );

      final response = await http.post(
        request['url'],
        body: json.encode(
          request['body'],
        ),
      );

      final data = json.decode(response.body);

      if (data['errcode'] == 'M_FORBIDDEN') {
        throw Exception('Invalid credentials, confirm and try again');
      }

      if (data['errcode'] != null) {
        throw Exception(data['error']);
      }

      store.dispatch(SetUser(
          user: User(
        userId: data['user_id'],
        deviceId: data['device_id'],
        accessToken: data['access_token'],
        homeserver: store.state.userStore
            .homeserver, // use homeserver from login call param instead
      )));

      authObserver.add(store.state.userStore.user);

      store.dispatch(ResetOnboarding());
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

      final user = store.state.userStore.user;

      final request = buildUserProfileRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: user.userId,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

      store.dispatch(SetUser(
        user: user.copyWith(
          displayName: data['displayname'],
          avatarUrl: data['avatar_url'],
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

      final request = buildCheckUsernameAvailability(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        username: store.state.userStore.username,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      final data = json.decode(response.body);

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

ThunkAction<AppState> logoutUser() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      // submit empty auth before logging out of matrix
      final authObserver = store.state.userStore.authObserver;
      authObserver.add(null);

      final request = buildLogoutUserRequest(
        protocol: protocol,
        homeserver: store.state.userStore.user.homeserver,
        accessToken: store.state.userStore.user.accessToken,
      );

      await http.post(
        request['url'],
        headers: request['headers'],
      );

      store.dispatch(ResetUser());
      store.dispatch(ResetRooms());
      store.dispatch(SetSynced(synced: false, lastSince: null));
    } catch (error) {
      store.dispatch(addAlert(type: 'warning', message: error.message));
    } finally {
      store.dispatch(SetLoading(loading: false));
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

      final loginType = store.state.userStore.loginType;

      final request = buildRegisterUserRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        username: store.state.userStore.username,
        password: store.state.userStore.password,
        type: loginType,
      );

      print('[createUser] calling ');
      final response = await http.post(
        request['url'],
        body: json.encode(request['body']),
      );

      final data = json.decode(response.body);

      print('[createUser] $data');

      // TODO: use homeserver from login call param instead in dev
      store.dispatch(SetUser(
        user: User(
          userId: data['user_id'],
          deviceId: data['device_id'],
          accessToken: data['access_token'],
          homeserver: data['user_id'].split(':')[1], // per matrix spec
        ),
      ));
      store.dispatch(ResetOnboarding());
    } catch (error) {
      print('[createUser] $error');
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
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: store.state.userStore.user.userId,
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

/**
 *  
 *  Wasted time on multipart code
 *  But now I know at least
    final contentTypes = fileType.split('/');
    final multipartFile = http.MultipartFile(
      'file',
      fileStream,
      fileLength,
      filename: fileName,
      contentType: MediaType(contentTypes[0], contentTypes[1]),
    );
    final multipartLength = multipartFile.length;
    requestUrl, not the file url
    print('multipartLength $multipartLength');

    final multipartUrl = Uri.parse(mediaUploadRequest['url']);
    final multipartRequest = http.MultipartRequest("POST", multipartUrl);

    multipartRequest.files.add(multipartFile);
    multipartRequest.fields['ext'] = contentTypes[1];
    multipartRequest.headers.addAll(mediaUploadRequest['headers']);

    print(
      'double checking ${multipartRequest.headers} ${multipartRequest.contentLength}',
    );
    final http.StreamedResponse mediaUploadResponseStream =
        await multipartRequest.send();
    final mediaUploadResponse =
        await http.Response.fromStream(mediaUploadResponseStream);

    final mediaUploadRequest = http.Request(
      'POST',
      mediaUploadRequest['url'],
    );
 */
ThunkAction<AppState> updateAvatarPhoto({File localFile}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final String fileType = lookupMimeType(localFile.path);
      print('fileType $fileType');

      final String fileName = store.state.userStore.user.displayName +
          "_profile_photo." +
          fileType.split('/')[1];
      print('fileName $fileName');

      final int fileLength = await localFile.length();
      print('fileLength $fileLength');

      final Stream<List<int>> fileStream = localFile.openRead();

      print('fileStream $fileStream');

      // // Upload the file to matrix
      final mediaUploadRequest = buildMediaUploadRequest(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        fileName: fileName,
        fileType: fileType,
        fileLength: fileLength,
      );

      // Logging to confirm
      print('${mediaUploadRequest['url']}');
      print('${mediaUploadRequest['headers']}');

      // Special StreamedRequest for Steam of bytes in post
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

      print('there is a god $mediaUploadResponse');

      // If upload fails, throw an error for the whole update
      final mediaUploadData = json.decode(mediaUploadResponse.body);

      print('help me $mediaUploadData');

      if (mediaUploadData['errcode'] != null) {
        throw mediaUploadData['error'];
      }
      final newAvatarUrl = mediaUploadData['content_uri'];

      final avatarUrlRequest = buildUpdateAvatarUrl(
        protocol: protocol,
        homeserver: store.state.userStore.homeserver,
        accessToken: store.state.userStore.user.accessToken,
        userId: store.state.userStore.user.userId,
        newAvatarUrl: newAvatarUrl,
      );

      final avatarUrlResponse = await http.post(
        avatarUrlRequest['url'],
        headers: avatarUrlRequest['request'],
        body: json.encode(avatarUrlRequest['body']),
      );

      final avatarUrlData = json.decode(avatarUrlResponse.body);
      if (avatarUrlData['errcode'] != null) {
        throw avatarUrlData['error'];
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

ThunkAction<AppState> setLoading(bool loading) {
  return (Store<AppState> store) async {
    store.dispatch(SetLoading(loading: loading));
  };
}

ThunkAction<AppState> selectHomeserver({dynamic homeserver}) {
  return (Store<AppState> store) async {
    store.dispatch(SetHomeserverValid(valid: true));
    store.dispatch(SetHomeserver(homeserver: homeserver['hostname']));
  };
}

ThunkAction<AppState> setHomeserver({String homeserver}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetHomeserverValid(valid: homeserver != null && homeserver.length > 0));
    store.dispatch(SetHomeserver(homeserver: homeserver.trim()));
  };
}

ThunkAction<AppState> setUsername({String username}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetUsernameValid(valid: username != null && username.length > 0));
    store.dispatch(SetUsername(username: username.trim()));
  };
}

ThunkAction<AppState> setPassword({String password}) {
  return (Store<AppState> store) async {
    store.dispatch(
        SetPasswordValid(valid: password != null && password.length > 0));
    store.dispatch(SetPassword(password: password.trim()));
  };
}
