import 'dart:typed_data';

import './actions.dart';
import './state.dart';

MediaStore mediaReducer([MediaStore state = const MediaStore(), dynamic action]) {
  switch (action.runtimeType) {
    case UpdateMediaCache:
      final mediaCache = Map<String, Uint8List>.from(state.mediaCache);
      mediaCache[action.mxcUri] = action.data;
      return state.copyWith(
        mediaCache: mediaCache,
      );
    case UpdateMediaChecks:
      final mediaChecks = Map<String, String>.from(state.mediaChecks);
      mediaChecks[action.mxcUri] = action.status;
      return state.copyWith(
        mediaChecks: mediaChecks,
      );
    case LoadMedia:
      return state.copyWith(
        mediaCache: action.media,
      );
    default:
      return state;
  }
}
