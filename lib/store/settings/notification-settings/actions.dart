import 'package:Tether/global/libs/matrix/index.dart';
import 'package:Tether/global/values.dart';
import 'package:Tether/store/settings/actions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';
import 'package:Tether/store/index.dart';

final protocol = DotEnv().env['PROTOCOL'];

/**
 * Fetch Remote Push Notification Service Rules
 */
ThunkAction<AppState> fetchNotifications() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchNotifications(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[fetchNotificationPushers] $data');
    } catch (error) {
      print('[fetchNotificationPushers] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Fetch Remote Push Notification Services
 */
ThunkAction<AppState> fetchNotificationPushers() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = await MatrixApi.fetchNotificationPushers(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[fetchNotificationPushers] $data');
    } catch (error) {
      print('[fetchNotificationPushers] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Fetch Remote Push Notification Service Rules
 */
ThunkAction<AppState> fetchNotificationPusherRules() {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final data = {'errcode': 'Not Implemented'};

      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[fetchNotificationPusherRules] $data');
    } catch (error) {
      print('[fetchNotificationPusherRules] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Set Pusher Device Token
 * 
 * NOTE: used to set iOS APNS token
 * 
 * Either the Apple Push Notification Service token for
 * this device or an email address for "email" notifications
 */
ThunkAction<AppState> setPusherDeviceToken(String token) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));
      store.dispatch(SetPusherToken(token: token));
      print('[setPusherDeviceToken] $token');
    } catch (error) {
      print('[setPusherDeviceToken] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

/**
 * Fetch Remote Push Notification Service
 */
ThunkAction<AppState> saveNotificationPusher({
  String kind = 'http', // can be 'email' with token as email
  bool erase = false,
}) {
  return (Store<AppState> store) async {
    try {
      store.dispatch(SetLoading(loading: true));

      final deviceId = store.state.authStore.user.deviceId;
      final devices = store.state.settingsStore.devices;
      final pusherKey = store.state.settingsStore.pusherToken;

      final currentDevice = devices.firstWhere(
        (device) => device.deviceId == deviceId,
      );

      final data = await MatrixApi.saveNotificationPusher(
        protocol: protocol,
        homeserver: store.state.authStore.user.homeserver,
        accessToken: store.state.authStore.user.accessToken,
        kind: erase ? null : kind,
        pushKey: pusherKey,
        appDisplayName: Values.appNameLong,
        appId: Values.appId,
        lang: Values.defaultLanguage,
        deviceDisplayName: currentDevice.displayName,
      );

      if (data['errcode'] != null) {
        throw data['error'];
      }

      print('[fetchNotificationPushers] $data');
    } catch (error) {
      print('[fetchNotificationPushers] $error');
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}
