import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:syphon/store/media/model.dart';

// @JsonSerializable(nullable: true, includeIfNull: true)
class MediaStore extends Equatable {
  final Map<String, Media> media;
  final Map<String, String> mediaStatus;
  final Map<String, Uint8List> mediaCache;

  const MediaStore({
    this.media = const {},
    this.mediaCache = const {},
    this.mediaStatus = const {},
  });

  @override
  List<Object?> get props => [
        mediaCache,
        mediaStatus,
        media,
      ];

  MediaStore copyWith({
    Map<String, Media>? media,
    Map<String, String>? mediaStatus,
    Map<String, Uint8List>? mediaCache,
  }) =>
      MediaStore(
        media: media ?? this.media,
        mediaCache: mediaCache ?? this.mediaCache,
        mediaStatus: mediaStatus ?? this.mediaStatus,
      );

  // custom json converter to allow Uint8List when in cache
  // TODO: how to make image-matrix.dart play nice with in component conversions
  // Would repeatedly update even if a locally cached version matched
  factory MediaStore.fromJson(Map<String, dynamic> json) {
    return MediaStore(
      mediaStatus: (json['mediaChecks'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as String),
      ),
      mediaCache: (json['mediaCache'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k, Uint8List.fromList((e as List).map((e) => e as int).toList())),
      ),
    );
  }

  Map<String, dynamic> toJson() => _$MediaStoreToJson(this);
  Map<String, dynamic> _$MediaStoreToJson(MediaStore instance) =>
      <String, dynamic>{
        'mediaCache':
            instance.mediaCache.map((key, value) => MapEntry(key, value)),
        'mediaChecks': instance.mediaStatus,
      };
}
