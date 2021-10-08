import 'dart:io';

import 'package:encrypt/encrypt.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';

class EncryptInfo {
  final IV? iv;
  final Key? key;
  final String? shasum;

  const EncryptInfo({
    this.key,
    this.iv,
    this.shasum,
  });

  EncryptInfo copyWith({
    IV? iv,
    Key? key,
    String? shasum,
  }) {
    return EncryptInfo(
      iv: iv ?? this.iv,
      key: key ?? this.key,
      shasum: shasum ?? this.shasum,
    );
  }

  factory EncryptInfo.generate() {
    return EncryptInfo(
        iv: IV.fromSecureRandom(8), // 64-bit / 8 byte
        key: Key.fromSecureRandom(32) // 256-bit / 32 byte
        );
  }
}

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
Future<File?> encryptMedia({
  required File localFile,
  EncryptInfo info = const EncryptInfo(),
  String? mediaName = 'encrypted-media',
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

    final ivUsed = info.iv ?? IV.fromSecureRandom(8); // 64-bit / 8 byte
    final keyUsed = info.key ?? Key.fromSecureRandom(32); // 256-bit / 32 byte
    final cipher = AES(keyUsed, mode: AESMode.ctr);

    final encryptedMedia = cipher.encrypt(await localFile.readAsBytes(), iv: ivUsed);

    final directory = await getTemporaryDirectory();
    final encryptFile = File(path.join(directory.path, fileName));

    return await encryptFile.writeAsBytes(encryptedMedia.bytes, flush: true);
  } catch (error) {
    printError(error.toString());
    return null;
  }
}
