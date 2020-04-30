import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class MediaStore extends Equatable {
  final bool fetching;
  final Map<String, Uint8List> mediaCache;

  const MediaStore({
    this.fetching = false,
    this.mediaCache = const {},
  });

  MediaStore copyWith({
    fetching,
    mediaCache,
  }) {
    return MediaStore(
      fetching: fetching ?? this.fetching,
      mediaCache: mediaCache ?? this.mediaCache,
    );
  }

  @override
  List<Object> get props => [
        fetching,
        mediaCache,
      ];
}
