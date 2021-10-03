import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';
import 'package:path/path.dart' as path;

///
/// a client should generate a single-use 256-bit AES key,
/// and encrypt the file using AES-CTR. The counter should be 64-bit long,
/// starting at 0 and prefixed by a random 64-bit Initialization Vector (IV),
/// which together form a 128-bit unique counter block.
///
Future<File?> encryptMedia({
  required File localFile,
  String? mediaName = 'profile-photo',
}) async {
  try {
    // Extension handling
    String? mimeType = lookupMimeType(localFile.path);

    if (localFile.path.contains('HEIC')) {
      mimeType = 'image/heic';
    } else if (mimeType == null) {
      throw 'Unsupported Media type for a message';
    }

    // Setting up params for saving encrypted file
    final String fileType = mimeType;
    final String fileExtension = fileType.split('/')[1];
    final String fileName = '$mediaName.$fileExtension';

    final iv = IV.fromSecureRandom(8); // 64-bit / 8 byte IV
    final key = Key.fromSecureRandom(32); // 256-bit / 32 byte

    final cipher = AES(key, mode: AESMode.ctr);

    final encryptedMedia = cipher.encrypt(await localFile.readAsBytes(), iv: iv);

    final directory = await getTemporaryDirectory();
    final encryptedFile = File(path.join(directory.path, fileName));

    encryptedFile.writeAsBytes(encryptedMedia.bytes, flush: true);

    return encryptedFile;
  } catch (error) {
    printError(error.toString());
    return null;
  }
}
