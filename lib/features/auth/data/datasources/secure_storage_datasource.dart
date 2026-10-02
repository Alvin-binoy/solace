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
  Future<int> getFailedAttempts();
  Future<void> incrementFailedAttempts();
  Future<void> resetFailedAttempts();
  Future<int> getLockoutRemainingSeconds();
  Future<void> setLockout(int seconds);
}

@LazySingleton(as: SecureStorageDatasource)
class SecureStorageDatasourceImpl implements SecureStorageDatasource {
  final FlutterSecureStorage _storage;
  static const _pinKey = 'solace_pin_hash';
  static const _failedAttemptsKey = 'solace_failed_attempts';
  static const _lockoutUntilKey = 'solace_lockout_until';

  SecureStorageDatasourceImpl(this._storage);

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  @override
  Future<void> savePin(String pin) async {
    try {
      final hash = _hashPin(pin);
      await _storage.write(key: _pinKey, value: hash);
      await resetFailedAttempts();
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
      final isCorrect = storedHash == inputHash;

      if (isCorrect) {
        await resetFailedAttempts();
      } else {
        await incrementFailedAttempts();
      }

      return isCorrect;
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
      await resetFailedAttempts();
    } catch (e) {
      throw const SecureStorageException('Failed to delete PIN.');
    }
  }

  @override
  Future<int> getFailedAttempts() async {
    try {
      final val = await _storage.read(key: _failedAttemptsKey);
      return val != null ? int.tryParse(val) ?? 0 : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> incrementFailedAttempts() async {
    try {
      final current = await getFailedAttempts();
      final updated = current + 1;
      await _storage.write(key: _failedAttemptsKey, value: updated.toString());
      if (updated >= 5) {
        await setLockout(30);
      }
    } catch (e) {
      // Ignore secure storage write error for attempts counter
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    try {
      await _storage.delete(key: _failedAttemptsKey);
      await _storage.delete(key: _lockoutUntilKey);
    } catch (e) {
      // Ignore cleanup error
    }
  }

  @override
  Future<int> getLockoutRemainingSeconds() async {
    try {
      final val = await _storage.read(key: _lockoutUntilKey);
      if (val == null) return 0;
      final lockoutUntil = int.tryParse(val) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final remaining = ((lockoutUntil - now) / 1000).ceil();
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> setLockout(int seconds) async {
    try {
      final lockoutUntil = DateTime.now().millisecondsSinceEpoch + (seconds * 1000);
      await _storage.write(key: _lockoutUntilKey, value: lockoutUntil.toString());
    } catch (e) {
      // Ignore write error
    }
  }
}
