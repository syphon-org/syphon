import 'dart:typed_data';

import 'package:Tether/global/libs/hive/type-ids.dart';
import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'state.g.dart';

@HiveType(typeId: MediaStoreHiveId)
class MediaStore extends Equatable {
  @HiveField(0)
  final bool fetching;
  @HiveField(1)
  final Map<String, Uint8List> mediaCache;

  static const hiveBox = 'MediaStore';

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
