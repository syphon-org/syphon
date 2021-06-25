import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/index.dart';

ThunkAction<AppState> fetchBaseUrl({required Homeserver homeserver}) {
  return (Store<AppState> store) async {
    // fetch homeserver well-known
    try {
      final response = await MatrixApi.checkHomeserver(
            protocol: store.state.authStore.protocol,
            homeserver: homeserver.hostname!,
          ) ??
          {};

      var identityUrl = response['m.identity_server'];
      var baseUrl = (response['m.homeserver']['base_url'] as String)
          .replaceAll('https://', '');

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.replaceRange(baseUrl.length - 1, null, '');
      }

      if (identityUrl != null) {
        identityUrl = (response['m.identity_server']['base_url'] as String)
            .replaceAll('https://', '');
      }

      return homeserver.copyWith(
        valid: true,
        baseUrl: baseUrl,
        identityUrl: identityUrl,
      );
    } catch (error) {
      return homeserver.copyWith(
        valid: false,
      );
    }
  };
}

ThunkAction<AppState> fetchServerVersion({required Homeserver homeserver}) {
  return (Store<AppState> store) async {
    // fetch homeserver well-known
    try {
      final response = await MatrixApi.checkVersion(
            protocol: store.state.authStore.protocol,
            homeserver: homeserver.hostname!,
          ) ??
          {};

      final versionExists = response['versions'] != null;

      return homeserver.copyWith(valid: versionExists);
    } catch (error) {
      return homeserver.copyWith(valid: false);
    }
  };
}
