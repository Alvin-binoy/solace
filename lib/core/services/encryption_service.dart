import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:injectable/injectable.dart';

@lazySingleton
class EncryptionService {
  // Derives a 32-byte (256-bit) key from a user password using SHA-256
  encrypt.Key _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  // Encrypts raw bytes and prepends the random IV so it can be extracted later
  Uint8List encryptData(Uint8List plainBytes, String password) {
    final key = _deriveKey(password);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encryptBytes(plainBytes, iv: iv);

    // Combine IV + Encrypted Data into a single byte array
    final result = BytesBuilder();
    result.add(iv.bytes);
    result.add(encrypted.bytes);
    return result.toBytes();
  }

  // Extracts the IV from the first 16 bytes and decrypts the rest
  Uint8List decryptData(Uint8List cipherBytes, String password) {
    if (cipherBytes.length < 16) {
      throw Exception('Invalid backup file format');
    }

    final key = _deriveKey(password);
    final ivBytes = cipherBytes.sublist(0, 16);
    final encryptedData = cipherBytes.sublist(16);

    final iv = encrypt.IV(Uint8List.fromList(ivBytes));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final decrypted = encrypter.decryptBytes(encrypt.Encrypted(encryptedData), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}