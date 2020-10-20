// Dart imports:
import 'dart:io';
import 'dart:typed_data';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

// Project imports:
import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';

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

ThunkAction<AppState> uploadMedia({
  File localFile,
  String mediaName = 'photo',
}) {
  return (Store<AppState> store) async {
    try {
      // Extension handling
      final String fileType = lookupMimeType(localFile.path);
      final String fileExtension = fileType.split('/')[1];

      // Setting up params for upload
      final int fileLength = await localFile.length();
      final Stream<List<int>> fileStream = localFile.openRead();
      final String fileName = '${mediaName}.${fileExtension}';

      // Create request vars for upload
      final data = await MatrixApi.uploadMedia(
        protocol: protocol,
        accessToken: store.state.authStore.user.accessToken,
        homeserver: store.state.authStore.currentUser.homeserver,
        fileName: fileName,
        fileType: fileType,
        fileLength: fileLength,
        fileStream: fileStream,
      );
      // If upload fails, throw an error for the whole update
      if (data['errcode'] != null) {
        throw data['error'];
      }

      return data;
    } catch (error) {
      store.dispatch(
        addAlert(origin: 'uploadMedia', message: error),
      );
      return null;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchThumbnail(
    {String mxcUri, double size, bool force = false}) {
  return (Store<AppState> store) async {
    try {
      final mediaCache = store.state.mediaStore.mediaCache;
      final mediaChecks = store.state.mediaStore.mediaChecks;

      // No op if cache is corrupted
      if (mediaCache == null) {
        return;
      }

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

      final params = {
        'protocol': protocol,
        'accessToken': store.state.authStore.user.accessToken,
        'homeserver': store.state.authStore.currentUser.homeserver,
        'mediaUri': mxcUri,
      };

      if (size != null) {
        params['size'] = size.toString();
      }

      final data = await compute(
        MatrixApi.fetchThumbnail,
        params,
      );

      final bodyBytes = data['bodyBytes'];

      debugPrint("FETCH THUMBNAIL ${bodyBytes.runtimeType.toString()}");
      debugPrint(bodyBytes.runtimeType.toString());
      store.dispatch(UpdateMediaCache(
        mxcUri: mxcUri,
        data: bodyBytes as List<int>,
      ));
    } catch (error) {
      debugPrint('[fetchThumbnail] $mxcUri $error');
      store.dispatch(UpdateMediaChecks(mxcUri: mxcUri, status: 'failure'));
    }
  };
}
