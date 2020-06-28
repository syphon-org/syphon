import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syphon/store/index.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/media.dart';
import 'package:http/http.dart' as http;

final protocol = DotEnv().env['PROTOCOL'];

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

      // No op if already cached data
      if (mediaCache.containsKey(mxcUri) && !force) {
        return;
      }

      final request = buildThumbnailRequest(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.currentUser.homeserver,
        mediaUri: mxcUri,
      );

      final response = await http.get(
        request['url'],
        headers: request['headers'],
      );

      if (response.headers['content-type'] == 'application/json') {
        final errorData = json.decode(response.body);
        throw errorData['errcode'];
      }

      final mediaData = response.bodyBytes;

      store.dispatch(UpdateMediaCache(
        mxcUri: mxcUri,
        data: mediaData,
      ));
    } catch (error) {
      debugPrint('[fetchThumbnail] error: ${mxcUri} $error');
    }
  };
}
