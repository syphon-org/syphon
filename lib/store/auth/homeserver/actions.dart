// Dart imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Package imports:
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/auth/homeserver/model.dart';
import 'package:syphon/store/index.dart';

final protocol = DotEnv().env['PROTOCOL'];

ThunkAction<AppState> fetchBaseUrl({Homeserver homeserver}) {
  return (Store<AppState> store) async {
    // fetch homeserver well-known
    try {
      final response = await MatrixApi.checkHomeserver(
            protocol: protocol,
            homeserver: homeserver.hostname,
          ) ??
          {};

      final identityUrl = (response['m.identity_server']['base_url'] as String)
          .replaceAll('https://', '');

      var baseUrl = (response['m.homeserver']['base_url'] as String)
          .replaceAll('https://', '');

      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.replaceRange(baseUrl.length - 1, null, '');
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
