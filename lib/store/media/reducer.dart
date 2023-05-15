import 'dart:typed_data';

import 'package:syphon/store/media/model.dart';

import './actions.dart';
import './state.dart';

MediaStore mediaReducer([MediaStore state = const MediaStore(), dynamic actionAny]) {
  switch (actionAny.runtimeType) {
    case UpdateMediaCache:
      final action = actionAny as UpdateMediaCache;

      final data = action.data;
      final mxcUri = action.mxcUri!;

      final medias = Map<String, Media>.from(state.media);
      final mediaCache = Map<String, Uint8List>.from(state.mediaCache);

      // Update media cache data
      if (data != null) {
        mediaCache[mxcUri] = data;
      }

      medias.putIfAbsent(
        mxcUri,
        () => Media(
          mxcUri: action.mxcUri,
          info: action.info,
          type: action.type,
          // data: _action.data TODO: pull only from the media object itself
        ),
      );

      medias.update(
        mxcUri,
        (value) => Media(
          mxcUri: action.mxcUri,
          info: value.info ?? action.info,
          type: action.type,
          // data: _action.data TODO: pull only from the media object itself
        ),
      );

      return state.copyWith(
        media: medias,
        mediaCache: mediaCache,
      );
    case UpdateMediaChecks:
      final action = actionAny as UpdateMediaChecks;
      final mediaChecks = Map<String, String>.from(state.mediaStatus);
      // ignore: cast_nullable_to_non_nullable
      mediaChecks[action.mxcUri!] = (action.status as MediaStatus).value;
      return state.copyWith(
        mediaStatus: mediaChecks,
      );
    default:
      return state;
  }
}
