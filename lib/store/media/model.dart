import 'dart:typed_data';

import 'package:moor/moor.dart' as moor;
import 'package:syphon/storage/moor/database.dart';
import 'package:syphon/store/media/encryption.dart';

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
