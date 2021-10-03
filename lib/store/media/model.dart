import 'dart:typed_data';

import 'package:moor/moor.dart' as moor;
import 'package:syphon/storage/moor/database.dart';

///
/// Media Class
///
/// Currently used for cold storage of media data only
///
class Media implements moor.Insertable<Media> {
  final String? mxcUri;
  final Uint8List? data;

  const Media({
    this.mxcUri,
    this.data,
  });

  @override
  Map<String, moor.Expression> toColumns(bool nullToAbsent) {
    return MediasCompanion(
      mxcUri: moor.Value(mxcUri!),
      data: moor.Value(data),
    ).toColumns(nullToAbsent);
  }
}
