import 'dart:typed_data';

import 'package:moor/moor.dart' as moor;
import 'package:syphon/storage/moor/database.dart';
import 'package:syphon/store/media/encryption.dart';

enum MediaType {
  encrypted,
  decrypted,
}

extension MediaTypeValue on MediaType {
  static String _value(MediaType val) {
    switch (val) {
      case MediaType.encrypted:
        return 'encrypted';
      case MediaType.decrypted:
        return 'decrypted';
    }
  }

  String get value => _value(this);
}

enum MediaStatus {
  SUCCESS,
  FAILURE,
  CHECKING,
  DECRYPTING,
}

extension MediaStatusValue on MediaStatus {
  static String _value(MediaStatus val) {
    switch (val) {
      case MediaStatus.SUCCESS:
        return 'success';
      case MediaStatus.FAILURE:
        return 'failure';
      case MediaStatus.CHECKING:
        return 'checking';
      case MediaStatus.DECRYPTING:
        return 'decrypting';
    }
  }

  String get value => _value(this);
}

///
/// Media Class
///
/// Currently used for cold storage of media data only
///
class Media implements moor.Insertable<Media> {
  final String? mxcUri;
  final String? type;
  final Uint8List? data;
  final EncryptInfo? info;

  const Media({
    this.mxcUri,
    this.type,
    this.data,
    this.info,
  });

  Media copyWith({
    String? mxcUri,
    String? type,
    Uint8List? data,
    EncryptInfo? info,
  }) =>
      Media(
        mxcUri: mxcUri ?? this.mxcUri,
        type: type ?? this.type,
        data: data ?? this.data,
        info: info ?? this.info,
      );

  @override
  Map<String, moor.Expression> toColumns(bool nullToAbsent) {
    return MediasCompanion(
      mxcUri: moor.Value(mxcUri!),
      type: moor.Value(type),
      data: moor.Value(data),
      info: moor.Value(info),
    ).toColumns(nullToAbsent);
  }
}
