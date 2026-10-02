import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/secure_storage_datasource.dart';

@Injectable(as: AuthRepository) // Tells the toolbox: "When asked for AuthRepository, give them this."
class AuthRepositoryImpl implements AuthRepository {
  final SecureStorageDatasource _secureStorage;

  AuthRepositoryImpl(this._secureStorage);

  @override
  Future<Either<Failure, void>> setupPin(String pin) async {
    try {
      await _secureStorage.savePin(pin);
      return const Right(null); // Right means Success
    } on SecureStorageException catch (e) {
      return Left(AuthFailure(e.message)); // Left means Error
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
  Future<Either<Failure, UserProfileEntity>> getProfile() async {
    // This is a temporary placeholder profile.
    // We will connect this to the real SQLite database soon!
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