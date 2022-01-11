import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/media/converters.dart';

///
/// Encrypt Media (for Matrix)
///
/// a client should generate a single-use 256-bit AES key,
/// and encrypt the file using AES-CTR. The counter should be 64-bit long,
/// starting at 0 and prefixed by a random 64-bit Initialization Vector (IV),
/// which together form a 128-bit unique counter block.
///
/// https://matrix.org/docs/spec/client_server/latest#sending-encrypted-attachments
///
Future<File?> scrubMedia({
  required File localFile,
  String? mediaName = 'media-default',
}) async {
  try {
    // Extension handling
    final mimeTypeOption = lookupMimeType(localFile.path);
    final mimeType = convertMimeTypes(localFile, mimeTypeOption);

    // Image file info
    final String fileType = mimeType;
    final String fileExtension = fileType.split('/')[1];
    final String fileName = '$mediaName-scrubbed.$fileExtension';
    final fileImage = await decodeImageFromList(
      localFile.readAsBytesSync(),
    );

    var format;

    switch (fileExtension.toLowerCase()) {
      case 'png':
        format = CompressFormat.png;
        break;
      case 'jpeg':
        format = CompressFormat.jpeg;
        break;
      case 'heic':
        format = CompressFormat.heic;
        break;
      case 'webp':
        format = CompressFormat.webp;
        break;
      default:
        // Can't remove exif info for this media type
        return localFile;
    }

    final mediaScrubbed = await FlutterImageCompress.compressWithFile(
      localFile.absolute.path,
      quality: 100,
      minWidth: fileImage.width,
      minHeight: fileImage.height,
      format: format,
      keepExif: false,
      numberOfRetries: 1,
      autoCorrectionAngle: false,
    );

    if (mediaScrubbed == null) {
      throw 'Failed to remove EXIF data from media';
    }

    final directory = await getTemporaryDirectory();
    final tempFile = File(path.join(directory.path, fileName));

    return await tempFile.writeAsBytes(mediaScrubbed, flush: true);
  } catch (error) {
    printError(error.toString());
    return null;
  }
}
