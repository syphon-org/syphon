// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:equatable/equatable.dart';

// @JsonSerializable(nullable: true, includeIfNull: true)
class MediaStore extends Equatable {
  final Map<String, String> mediaChecks; // Map<mxcUri, status>
  final Map<String, Uint8List> mediaCache;

  const MediaStore({
    this.mediaCache = const {},
    this.mediaChecks = const {},
  });

  @override
  List<Object> get props => [
        mediaCache,
        mediaChecks,
      ];

  MediaStore copyWith({
    mediaCache,
    mediaChecks,
  }) =>
      MediaStore(
        mediaCache: mediaCache ?? this.mediaCache,
        mediaChecks: mediaChecks ?? this.mediaChecks,
      );

  // custom json converter to allow Uint8List when in cache
  // TODO: how to make image-matrix.dart play nice with in component conversions
  // Would repeatedly update even if a locally cached version matched
  factory MediaStore.fromJson(Map<String, dynamic> json) {
    return MediaStore(
      mediaCache: (json['mediaCache'] as Map<String, dynamic>)?.map(
        (k, e) => MapEntry(
            k, Uint8List.fromList((e as List)?.map((e) => e as int)?.toList())),
      ),
      mediaChecks: (json['mediaChecks'] as Map<String, dynamic>)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );
  }

  Map<String, dynamic> toJson() => _$MediaStoreToJson(this);
  Map<String, dynamic> _$MediaStoreToJson(MediaStore instance) =>
      <String, dynamic>{
        'mediaCache': instance.mediaCache
            .map((key, value) => MapEntry(key, value as List<int>)),
        'mediaChecks': instance.mediaChecks,
      };
}
