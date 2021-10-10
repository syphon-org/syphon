import 'dart:io';

import 'package:syphon/global/print.dart';

///
/// Overrides mimetypes
///
/// Format a message as a reply to another
/// https://matrix.org/docs/spec/client_server/latest#rich-replies
/// https://github.com/matrix-org/matrix-doc/pull/1767
///
///
String convertMimeTypes(
  File file,
  String? mimeType,
) {
  if (file.path.toLowerCase().contains('heic')) {
    return 'image/heic';
  }

  // printInfo('$mimeType ${file.path}');

  if (mimeType == null) {
    throw 'Unsupported Media type for a message';
  }

  return mimeType;
}