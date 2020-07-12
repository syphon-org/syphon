import 'dart:typed_data';

import 'package:syphon/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: MediaStoreHiveId)
class MediaStore extends Equatable {
  @HiveField(0)
  final bool fetching;
  @HiveField(1)
  final Map<String, Uint8List> mediaCache;

  // Map<mxcUri, status>
  @HiveField(2)
  final Map<String, String> mediaChecks;

  static const hiveBox = 'MediaStore';

  const MediaStore({
    this.fetching = false,
    this.mediaCache = const {},
    this.mediaChecks = const {},
  });

  MediaStore copyWith({
    fetching,
    mediaCache,
    mediaChecks,
  }) {
    return MediaStore(
      fetching: fetching ?? this.fetching,
      mediaCache: mediaCache ?? this.mediaCache,
      mediaChecks: mediaChecks ?? this.mediaChecks,
    );
  }

  @override
  List<Object> get props => [
        fetching,
        mediaCache,
        mediaChecks,
      ];
}
