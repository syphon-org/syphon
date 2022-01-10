import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:redux/redux.dart';
import 'package:redux_thunk/redux_thunk.dart';

import 'package:syphon/global/libs/matrix/index.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/storage/index.dart';
import 'package:syphon/store/alerts/actions.dart';
import 'package:syphon/store/index.dart';
import 'package:syphon/store/media/converters.dart';
import 'package:syphon/store/media/encryption.dart';
import 'package:syphon/store/media/model.dart';
import 'package:syphon/store/media/storage.dart';

class LoadMedia {
  final Map<String, Uint8List> mediaMap;
  LoadMedia({required this.mediaMap});
}

class UpdateMediaChecks {
  final String? mxcUri;
  final MediaStatus? status;

  UpdateMediaChecks({
    this.mxcUri,
    this.status,
  });
}

class UpdateMediaCache {
  final String? mxcUri;
  final String? type;
  final Uint8List? data;
  final EncryptInfo? info;

  UpdateMediaCache({
    this.mxcUri,
    this.type,
    this.data,
    this.info,
  });
}

ThunkAction<AppState> uploadMedia({
  required File localFile,
  String? mediaName = 'media-default',
}) {
  return (Store<AppState> store) async {
    try {
      // Extension handling
      final mimeTypeOption = lookupMimeType(localFile.path);
      final mimeType = convertMimeTypes(localFile, mimeTypeOption);

      final String fileType = mimeType;
      final String fileExtension = fileType.split('/')[1];

      // Setting up params for upload
      final int fileLength = await localFile.length();
      final Stream<List<int>> fileStream = localFile.openRead();
      final String fileName = '$mediaName.$fileExtension';

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

ThunkAction<AppState> fetchMedia({
  String? mxcUri,
  double? size,
  EncryptInfo? info, // allows quicker local provided media decryption
  bool force = false,
  bool thumbnail = false,
}) {
  return (Store<AppState> store) async {
    try {
      final mediaCache = store.state.mediaStore.mediaCache;
      final mediaStatus = store.state.mediaStore.mediaStatus;
      final medias = store.state.mediaStore.media;

      if (mxcUri == null || mxcUri.isEmpty) {
        return;
      }

      // Noop if already cached data
      if (mediaCache.containsKey(mxcUri) && !force) {
        return;
      }

      final currentStatus = mediaStatus[mxcUri];
      // Noop if currently checking, failed, or decrypting
      if (mediaStatus.containsKey(mxcUri) &&
          (currentStatus == MediaStatus.CHECKING.value ||
              currentStatus == MediaStatus.FAILURE.value ||
              currentStatus == MediaStatus.DECRYPTING.value) &&
          !force) {
        return;
      }

      final currentMedia = medias[mxcUri];

      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.CHECKING),
      );

      // check if the media is only located in cold storage
      if (await checkMedia(mxcUri, storage: Storage.database!)) {
        var media = await loadMedia(
          mxcUri: mxcUri,
          storage: Storage.database!,
        );

        // Dont assume decrypted from cold storage
        if (media != null && media.data != null) {
          if (media.info?.key != null) {
            store.dispatch(
              UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.DECRYPTING),
            );
            media = media.copyWith(
              data: await decryptMediaData(localData: media.data!, info: currentMedia?.info),
            );
          }

          store.dispatch(
            UpdateMediaCache(mxcUri: mxcUri, data: media.data, info: media.info),
          );

          return store.dispatch(
            UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.SUCCESS),
          );
        }
      }

      var data;

      if (thumbnail) {
        data = await compute(MatrixApi.fetchThumbnailThreaded, {
          'protocol': store.state.authStore.protocol,
          'accessToken': store.state.authStore.user.accessToken,
          'homeserver': store.state.authStore.currentUser.homeserver,
          'mediaUri': mxcUri,
          'size': size,
          'proxySettings': store.state.settingsStore.proxySettings,
        });
      } else {
        data = await compute(MatrixApi.fetchMediaThreaded, {
          'protocol': store.state.authStore.protocol,
          'accessToken': store.state.authStore.user.accessToken,
          'homeserver': store.state.authStore.currentUser.homeserver,
          'mediaUri': mxcUri,
          'proxySettings': store.state.settingsStore.proxySettings,
        });
      }

      var bodyBytes = data['bodyBytes'] as Uint8List?;

      // Resolve encrypted info for media message based on available sources
      final currentInfo = info ?? currentMedia?.info ?? const EncryptInfo();
      if (currentInfo.key != null && bodyBytes != null) {
        store.dispatch(
          UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.DECRYPTING),
        );

        bodyBytes = await decryptMediaData(localData: bodyBytes, info: info ?? currentMedia?.info);
      }

      store.dispatch(
        UpdateMediaCache(mxcUri: mxcUri, data: bodyBytes, info: info),
      );

      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.SUCCESS),
      );
    } catch (error) {
      printError('[fetchMedia] $mxcUri $error');
      store.dispatch(
        UpdateMediaChecks(mxcUri: mxcUri, status: MediaStatus.FAILURE),
      );
    }
  };
}
