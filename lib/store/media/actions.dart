import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/index.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

final protocol = DotEnv().env['PROTOCOL'];

class UpdateMediaChecks {
  final String mxcUri;
  final String status;

  UpdateMediaChecks({
    this.mxcUri,
    this.status,
  });
}

class UpdateMediaCache {
  final String mxcUri;
  final Uint8List data;

  UpdateMediaCache({
    this.mxcUri,
    this.data,
  });
}

ThunkAction<AppState> fetchThumbnail({String mxcUri, bool force = false}) {
  return (Store<AppState> store) async {
    try {
      final mediaCache = store.state.mediaStore.mediaCache;
      final mediaChecks = store.state.mediaStore.mediaChecks;

      // No op if already cached data
      if (mediaCache.containsKey(mxcUri) && !force) {
        return;
      }

      // No op if already fetching or failed
      if (mediaChecks.containsKey(mxcUri) &&
          (mediaChecks[mxcUri] == 'checking' ||
              mediaChecks[mxcUri] == 'failure') &&
          !force) {
        return;
      }

      store.dispatch(UpdateMediaChecks(mxcUri: mxcUri, status: 'checking'));

      final data = await compute(
        MatrixApi.fetchThumbnail,
        {
          'protocol': protocol,
          'accessToken': store.state.authStore.user.accessToken,
          'homeserver': store.state.authStore.currentUser.homeserver,
          'mediaUri': mxcUri,
        },
      );

      final bodyBytes = data['bodyBytes'];

      store.dispatch(UpdateMediaCache(
        mxcUri: mxcUri,
        data: bodyBytes,
      ));
    } catch (error) {
      debugPrint('[fetchThumbnail] $mxcUri $error');
      store.dispatch(UpdateMediaChecks(mxcUri: mxcUri, status: 'failure'));
    }
  };
}
