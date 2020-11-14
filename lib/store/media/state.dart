// Dart imports:
import 'dart:typed_data';

// Package imports:
import 'package:equatable/equatable.dart';

// @JsonSerializable(nullable: true, includeIfNull: true)
class MediaStore extends Equatable {
  final bool fetching;
  final Map<String, String> mediaChecks; // Map<mxcUri, status>
  final Map<String, Uint8List> mediaCache;

  const MediaStore({
    this.fetching = false,
    this.mediaCache = const {},
    this.mediaChecks = const {},
  });

  @override
  List<Object> get props => [
        fetching,
        mediaCache,
        mediaChecks,
      ];

  MediaStore copyWith({
    fetching,
    mediaCache,
    mediaChecks,
  }) =>
      MediaStore(
        fetching: fetching ?? this.fetching,
        mediaCache: mediaCache ?? this.mediaCache,
        mediaChecks: mediaChecks ?? this.mediaChecks,
      );

  // NOTE: custom json converter to allow Uint8List when in cache
  // TODO: figure out how to make image-matrix.dart play nice with in component coonversions
  // Would repeatedly update even if a locally cached version matched
  factory MediaStore.fromJson(Map<String, dynamic> json) {
    return MediaStore(
      fetching: json['fetching'] as bool,
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
        'fetching': instance.fetching,
        'mediaCache': instance.mediaCache
            .map((key, value) => MapEntry(key, value as List<int>)),
        'mediaChecks': instance.mediaChecks,
      };
}
