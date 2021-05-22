import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

var _random = Random.secure();

abstract class CacheCodec {
  String? get signature;

  /// The actual codec used
  Codec<String?, String>? get codec;

  /// [codec] must convert between a map and a single line string
  factory CacheCodec({
    required String? signature,
    required Codec<String?, String>? codec,
  }) =>
      CacheCodec(
        signature: signature,
        codec: codec,
      );
}

/// Random bytes generator
Uint8List _randBytes(int length) {
  return Uint8List.fromList(
    List<int>.generate(length, (i) => _random.nextInt(256)),
  );
}

/// Generate an encryption password based on a user input password
///
/// It uses MD5 which generates a 16 bytes blob, size needed for Salsa20
Uint8List _generateEncryptPassword(String password) {
  var blob = Uint8List.fromList(md5.convert(utf8.encode(password)).bytes);
  assert(blob.length == 16);
  return blob;
}

class _EncryptEncoder extends Converter<String, String> {
  final AES aes;

  _EncryptEncoder(this.aes);

  @override
  String convert(String input) {
    // Generate random initial value
    final iv = _randBytes(8);
    final ivEncoded = base64.encode(iv);
    assert(ivEncoded.length == 12);

    // Encode the input value
    final encoded =
        Encrypter(aes).encrypt(json.encode(input), iv: IV(iv)).base64;

    // Prepend the initial value
    return '$ivEncoded$encoded';
  }
}

class _EncryptDecoder extends Converter<String, String> {
  final AES aes;

  _EncryptDecoder(this.aes);

  @override
  String convert(String input) {
    // Read the initial value that was prepended
    assert(input.length >= 12);
    final iv = base64.decode(input.substring(0, 12));

    // Extract the real input
    input = input.substring(12);

    // Decode the input
    return Encrypter(aes).decrypt64(input, iv: IV(iv));
  }
}

/// Salsa20 based Codec
class _EncryptCodec extends Codec<String, String> {
  late _EncryptEncoder _encoder;
  late _EncryptDecoder _decoder;

  _EncryptCodec(Uint8List passwordBytes) {
    var aes = AES(Key(passwordBytes), mode: AESMode.ctr, padding: null);
    _encoder = _EncryptEncoder(aes);
    _decoder = _EncryptDecoder(aes);
  }

  @override
  Converter<String, String> get decoder => _decoder;

  @override
  Converter<String, String> get encoder => _encoder;
}

/// Our plain text signature
const _encryptCodecSignature = 'encrypt';

CacheCodec initCacheEncrypter({required String password}) => CacheCodec(
    signature: _encryptCodecSignature,
    codec: _EncryptCodec(_generateEncryptPassword(password)));
