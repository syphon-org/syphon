import 'dart:typed_data';

import './state.dart';
import './actions.dart';

MediaStore mediaReducer(
    [MediaStore state = const MediaStore(), dynamic action]) {
  switch (action.runtimeType) {
    case UpdateMediaCache:
      final mediaCache = Map<String, Uint8List>.from(state.mediaCache);
      mediaCache[action.mxcUri] = action.data;
      return state.copyWith(
        mediaCache: mediaCache,
      );
      break;
    case UpdateMediaChecks:
      final mediaChecks = Map<String, String>.from(state.mediaChecks);
      mediaChecks[action.mxcUri] = action.status;
      return state.copyWith(
        mediaChecks: mediaChecks,
      );
      break;
    default:
      return state;
  }
}
