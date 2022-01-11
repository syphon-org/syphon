import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:encrypt/encrypt.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:syphon/global/print.dart';
import 'package:syphon/store/media/converters.dart';

part 'encryption.g.dart';

@JsonSerializable()
class EncryptInfo {
  final String? iv; // base64
  final String? key; // base64
  final String? shasum;

  const EncryptInfo({
    this.key,
    this.iv,
    this.shasum,
  });

  EncryptInfo copyWith({
    String? iv,
    String? key,
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
      // 64-bit / 8 byte + counter (not doing this, just another 8 bytes)
      iv: IV.fromSecureRandom(16).base64,
      key: Key.fromSecureRandom(32).base64, // 256-bit / 32 byte
    );
  }

  List<int> keyToBytes() {
    return Key.fromBase64(key!).bytes.toList();
  }

  Map<String, dynamic> toJson() => _$EncryptInfoToJson(this);

  factory EncryptInfo.fromJson(Map<String, dynamic> json) => _$EncryptInfoFromJson(json);
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
    final mimeTypeOption = lookupMimeType(localFile.path);
    final mimeType = convertMimeTypes(localFile, mimeTypeOption);

    // Setting up params for saving encrypted file
    final String fileType = mimeType;
    final String fileExtension = fileType.split('/')[1];
    final String fileName = '$mediaName.$fileExtension';

    final ivUsed = IV.fromBase64(info.iv!);
    final keyUsed = Key.fromBase64(info.key!);
    final cipher = AES(keyUsed, mode: AESMode.ctr, padding: null);

    final encryptedMedia = cipher.encrypt(await localFile.readAsBytes(), iv: ivUsed);
    final directory = await getTemporaryDirectory();
    final encryptFile = File(path.join(directory.path, fileName));

    return await encryptFile.writeAsBytes(encryptedMedia.bytes, flush: true);
  } catch (error) {
    printError(error.toString());
    return null;
  }
}

Future<Uint8List?> decryptMediaData({
  required Uint8List localData,
  EncryptInfo? info = const EncryptInfo(),
}) async {
  try {
    final iv = info?.iv;
    final key = info?.key;

    final ivUsed = IV.fromBase64(base64.normalize(iv!));
    final keyUsed = Key.fromBase64(base64.normalize(key!));
    final cipher = AES(keyUsed, mode: AESMode.ctr, padding: null);

    return cipher.decrypt(Encrypted.fromBase64(base64.encode(localData)), iv: ivUsed);
  } catch (error) {
    printError(error.toString());
    rethrow;
  }
}
