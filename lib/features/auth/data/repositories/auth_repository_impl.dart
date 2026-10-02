import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/secure_storage_datasource.dart';

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageDatasource _secureStorage;
  final LocalAuthentication _localAuth = LocalAuthentication();

  AuthRepositoryImpl(this._secureStorage);

  @override
  Future<Either<Failure, void>> setupPin(String pin) async {
    try {
      await _secureStorage.savePin(pin);
      return const Right(null);
    } on SecureStorageException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPin(String pin) async {
    try {
      final isCorrect = await _secureStorage.verifyPin(pin);
      return Right(isCorrect);
    } on SecureStorageException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, int>> getLockoutRemainingSeconds() async {
    try {
      final remaining = await _secureStorage.getLockoutRemainingSeconds();
      return Right(remaining);
    } catch (e) {
      return const Right(0);
    }
  }

  @override
  Future<Either<Failure, bool>> authenticateWithBiometrics() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canAuthenticateWithBiometrics || !isDeviceSupported) {
        return const Left(AuthFailure('Biometrics not available on this device.'));
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock Solace',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await _secureStorage.resetFailedAttempts();
      }

      return Right(authenticated);
    } catch (e) {
      return const Left(AuthFailure('Biometric authentication failed.'));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> getProfile() async {
    return Right(UserProfileEntity(
      id: 1,
      displayName: 'User',
      biometricsEnabled: false,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Either<Failure, bool>> hasPin() async {
    try {
      final exists = await _secureStorage.hasPin();
      return Right(exists);
    } on SecureStorageException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return const Left(AuthFailure('An unexpected error occurred.'));
    }
  }

  @override
  Future<Either<Failure, void>> clearPin() async {
    try {
      await _secureStorage.deletePin();
      return const Right(null);
    } catch (e) {
      return const Left(AuthFailure('Failed to clear PIN.'));
    }
  }
}
