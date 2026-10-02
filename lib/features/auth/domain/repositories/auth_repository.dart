import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_profile_entity.dart';

abstract class AuthRepository {
  // Returns nothing on success, or a Failure on error
  Future<Either<Failure, void>> setupPin(String pin);

  // Returns true if PIN is correct, or a Failure on error
  Future<Either<Failure, bool>> verifyPin(String pin);
  Future<Either<Failure, bool>> hasPin();
  Future<Either<Failure, void>> clearPin();

  // Returns the user's profile, or a Failure on error
  Future<Either<Failure, UserProfileEntity>> getProfile();
}