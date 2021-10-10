import 'dart:typed_data';

import 'package:syphon/store/media/model.dart';

import './actions.dart';
import './state.dart';

MediaStore mediaReducer([MediaStore state = const MediaStore(), dynamic action]) {
  switch (action.runtimeType) {
    case UpdateMediaCache:
      final _action = action as UpdateMediaCache;

      final data = _action.data;
      final mxcUri = _action.mxcUri!;

      final medias = Map<String, Media>.from(state.media);
      final mediaCache = Map<String, Uint8List>.from(state.mediaCache);

      // Update media cache data
      if (data != null) {
        mediaCache[mxcUri] = data;
      }

      medias.putIfAbsent(
        mxcUri,
        () => Media(
          mxcUri: _action.mxcUri,
          info: _action.info,
          // data: _action.data TODO: pull only from the media object itself
        ),
      );

      medias.update(
        mxcUri,
        (value) => Media(
          mxcUri: _action.mxcUri,
          info: value.info ?? _action.info,
          // data: _action.data TODO: pull only from the media object itself
        ),
      );

      return state.copyWith(
        media: medias,
        mediaCache: mediaCache,
      );
    case UpdateMediaChecks:
      final mediaChecks = Map<String, String>.from(state.mediaStatus);
      mediaChecks[action.mxcUri] = action.status;
      return state.copyWith(
        mediaStatus: mediaChecks,
      );
    default:
      return state;
  }
}
