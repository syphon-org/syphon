import 'package:Tether/global/libs/matrix/index.dart';
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
  return (Store<AppState> store) async {};
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

      print('[fetchNotificationPushers] $data');

      if (data['errcode'] != null) {
        throw data['error'];
      }
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
ThunkAction<AppState> saveNotificationPusherRules() {
  return (Store<AppState> store) async {};
}
