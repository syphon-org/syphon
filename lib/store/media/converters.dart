import 'dart:io';

///
/// Overrides mimetypes
///
/// Formatting mimeTypes through lookup
/// didn't work for heic
///
String convertMimeTypes(
  File file,
  String? mimeType,
) {
  if (file.path.toLowerCase().contains('heic')) {
    return 'image/heic';
  }

  if (mimeType == null) {
    throw 'Unsupported Media type for a message';
  }

  return mimeType;
}
