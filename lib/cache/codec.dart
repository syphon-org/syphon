import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

const IV_LENGTH = 16;
const IV_LENGTH_BASE_64 = IV_LENGTH + (IV_LENGTH / 2);

/// Random bytes generator
Uint8List _generateIV(int length) {
  return IV.fromSecureRandom(length).bytes;
}

/// Generate an encryption password based on a user input password
Key _generateEncryptPassword(String password) {
  return Key.fromBase64(password);
}

class _EncryptEncoder extends Converter<String, String> {
  final AES aes;

  _EncryptEncoder(this.aes);

  @override
  String convert(String input) {
    // Generate random initial value
    final iv = _generateIV(IV_LENGTH);
    final ivEncoded = base64.encode(iv);
    assert(ivEncoded.length == IV_LENGTH_BASE_64.round());

    // Encode the input value
    final encoded = Encrypter(aes).encrypt(input, iv: IV(iv)).base64;

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
    assert(input.length >= IV_LENGTH_BASE_64.round());
    final iv = base64.decode(input.substring(0, IV_LENGTH_BASE_64.round()));

    // Extract the real input
    input = input.substring(IV_LENGTH_BASE_64.round());

    // Decode the input
    return Encrypter(aes).decrypt64(input, iv: IV(iv));
  }
}

/// Salsa20 based Codec
class EncryptCodec extends Codec<String, String> {
  late _EncryptEncoder _encoder;
  late _EncryptDecoder _decoder;

  EncryptCodec(Key passwordBytes) {
    var aes = AES(passwordBytes, mode: AESMode.ctr, padding: null);

    _encoder = _EncryptEncoder(aes);
    _decoder = _EncryptDecoder(aes);
  }

  @override
  Converter<String, String> get decoder => _decoder;

  @override
  Converter<String, String> get encoder => _encoder;
}

EncryptCodec initCacheEncrypter({required String password}) =>
    EncryptCodec(_generateEncryptPassword(password));
