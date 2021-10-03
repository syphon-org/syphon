import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:mime/mime.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/storage.dart';

class MediaStatus {
  static const FAILURE = 'failure';
  static const CHECKING = 'checking';
  static const SUCCESS = 'success';
}

class UpdateMediaChecks {
  final String? mxcUri;
  final String? status;

  UpdateMediaChecks({
    this.mxcUri,
    this.status,
  });
}

class UpdateMediaCache {
  final String? mxcUri;
  final Uint8List? data;

  UpdateMediaCache({
    this.mxcUri,
    this.data,
  });
}

ThunkAction<AppState> uploadMedia({
  required File localFile,
  String? mediaName = 'profile-photo',
}) {
  return (Store<AppState> store) async {
    try {
      // Extension handling
      String? mimeType = lookupMimeType(localFile.path);

      if (localFile.path.contains('HEIC')) {
        mimeType = 'image/heic';
      } else if (mimeType == null) {
        throw 'Unsupported Media type for a message';
      }

      final String fileType = mimeType;
      final String fileExtension = fileType.split('/')[1];

      // Setting up params for upload
      final int fileLength = await localFile.length();
      final Stream<List<int>> fileStream = localFile.openRead();
      final String fileName = '$mediaName.$fileExtension';

      // TODO: add encrypted info
      // Create request vars for upload
      final data = await MatrixApi.uploadMedia(
        protocol: store.state.authStore.protocol,
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
      printError(error.toString());

      store.dispatch(addAlert(
        origin: 'uploadMedia',
        message: error.toString(),
      ));
      return null;
    } finally {
      store.dispatch(SetLoading(loading: false));
    }
  };
}

ThunkAction<AppState> fetchMedia({String? mxcUri, bool force = false}) {
  return (Store<AppState> store) async {
    try {
      final mediaCache = store.state.mediaStore.mediaCache;
      final mediaChecks = store.state.mediaStore.mediaChecks;

      // Noop if already cached data
      if (mediaCache.containsKey(mxcUri) && !force) {
        return;
      }

      // Noop if currently checking or failed
      if (mediaChecks.containsKey(mxcUri) &&
          (mediaChecks[mxcUri!] == MediaStatus.CHECKING || mediaChecks[mxcUri] == MediaStatus.FAILURE) &&
          !force) {
        return;
      }

      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.CHECKING),
      );

      // check if the media is only located in cold storage
      if (await checkMedia(mxcUri, storage: Storage.database!)) {
        final storedData = await loadMedia(
          mxcUri: mxcUri,
          storage: Storage.database!,
        );

        if (storedData != null) {
          store.dispatch(UpdateMediaCache(mxcUri: mxcUri, data: storedData));
          return;
        }
      }

      final data = await compute(MatrixApi.fetchMediaMapped, {
        'protocol': store.state.authStore.protocol,
        'accessToken': store.state.authStore.user.accessToken,
        'homeserver': store.state.authStore.currentUser.homeserver,
        'mediaUri': mxcUri,
      });

      final bodyBytes = data['bodyBytes'];

      store.dispatch(
        UpdateMediaCache(mxcUri: mxcUri, data: bodyBytes),
      );
      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.SUCCESS),
      );
    } catch (error) {
      debugPrint('[fetchThumbnail] $mxcUri $error');
      store.dispatch(UpdateMediaChecks(
        mxcUri: mxcUri,
        status: MediaStatus.FAILURE,
      ));
    }
  };
}

ThunkAction<AppState> fetchThumbnail({String? mxcUri, double? size, bool force = false}) {
  return (Store<AppState> store) async {
    try {
      final mediaCache = store.state.mediaStore.mediaCache;
      final mediaChecks = store.state.mediaStore.mediaChecks;

      // Noop if already cached data
      if (mediaCache.containsKey(mxcUri) && !force) {
        return;
      }

      // Noop if currently checking or failed
      if (mediaChecks.containsKey(mxcUri) &&
          (mediaChecks[mxcUri!] == MediaStatus.CHECKING || mediaChecks[mxcUri] == MediaStatus.FAILURE) &&
          !force) {
        return;
      }

      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.CHECKING),
      );

      // check if the media is only located in cold storage
      if (await checkMedia(mxcUri, storage: Storage.database!)) {
        final storedData = await loadMedia(
          mxcUri: mxcUri,
          storage: Storage.database!,
        );

        if (storedData != null) {
          store.dispatch(UpdateMediaCache(mxcUri: mxcUri, data: storedData));
          return;
        }
      }

      final data = await compute(MatrixApi.fetchThumbnail, {
        'protocol': store.state.authStore.protocol,
        'accessToken': store.state.authStore.user.accessToken,
        'homeserver': store.state.authStore.currentUser.homeserver,
        'mediaUri': mxcUri,
        'sizee': size,
      });

      final bodyBytes = data['bodyBytes'];

      store.dispatch(
        UpdateMediaCache(mxcUri: mxcUri, data: bodyBytes),
      );
      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.SUCCESS),
      );
    } catch (error) {
      debugPrint('[fetchThumbnail] $mxcUri $error');
      store.dispatch(UpdateMediaChecks(
        mxcUri: mxcUri,
        status: MediaStatus.FAILURE,
      ));
    }
  };
}
