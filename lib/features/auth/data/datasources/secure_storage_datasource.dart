import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/exceptions.dart';

abstract class SecureStorageDatasource {
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<bool> hasPin();
  Future<void> deletePin();
}

@LazySingleton(as: SecureStorageDatasource)
class SecureStorageDatasourceImpl implements SecureStorageDatasource {
  final FlutterSecureStorage _storage;
  static const _pinKey = 'solace_pin_hash';

  SecureStorageDatasourceImpl(this._storage);

  String _hashPin(String pin) {
    // Scrambles the PIN into an unrecognizable string (SHA-256)
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<void> savePin(String pin) async {
    try {
      final hash = _hashPin(pin);
      await _storage.write(key: _pinKey, value: hash);
    } catch (e) {
      throw const SecureStorageException('Failed to save PIN securely.');
    }
  }

  @override
  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      if (storedHash == null) return false;

      final inputHash = _hashPin(pin);
      return storedHash == inputHash;
    } catch (e) {
      throw const SecureStorageException('Failed to verify PIN.');
    }
  }

  @override
  Future<bool> hasPin() async {
    try {
      final storedHash = await _storage.read(key: _pinKey);
      return storedHash != null;
    } catch (e) {
      throw const SecureStorageException('Failed to check PIN existence.');
    }
  }

  @override
  Future<void> deletePin() async {
    try {
      await _storage.delete(key: _pinKey);
    } catch (e) {
      throw const SecureStorageException('Failed to delete PIN.');
    }
  }
}