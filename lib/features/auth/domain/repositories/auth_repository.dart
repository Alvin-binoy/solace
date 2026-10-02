import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> setupPin(String pin);
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, bool>> hasPin();
  Future<Either<Failure, void>> clearPin();
  Future<Either<Failure, int>> getLockoutRemainingSeconds();
  Future<Either<Failure, bool>> authenticateWithBiometrics();
  Future<Either<Failure, UserProfileEntity>> getProfile();
}
