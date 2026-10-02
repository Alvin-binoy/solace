import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/check_auth_status_use_case.dart';
import '../../domain/use_cases/setup_pin_use_case.dart';
import '../../domain/use_cases/verify_pin_use_case.dart';
import '../../domain/use_cases/clear_pin_use_case.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SetupPinUseCase _setupPin;
  final VerifyPinUseCase _verifyPin;
  final CheckAuthStatusUseCase _checkAuthStatus;
  final ClearPinUseCase _clearPin;
  final AuthRepository _authRepository;

  AuthBloc(
    this._setupPin,
    this._verifyPin,
    this._checkAuthStatus,
    this._clearPin,
    this._authRepository,
  ) : super(AuthInitial()) {
    on<SetupPinEvent>(_onSetupPin);
    on<VerifyPinEvent>(_onVerifyPin);
    on<BiometricAuthEvent>(_onBiometricAuth);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ClearPinEvent>(_onClearPin);
  }

  Future<void> _onSetupPin(SetupPinEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _setupPin(event.pin);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthSuccess('PIN set successfully!')),
    );
  }

  Future<void> _onVerifyPin(VerifyPinEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Check lockout remaining seconds first
    final lockoutRes = await _authRepository.getLockoutRemainingSeconds();
    final lockoutSeconds = lockoutRes.getOrElse((_) => 0);
    if (lockoutSeconds > 0) {
      emit(AuthLockoutState(lockoutSeconds));
      return;
    }

    final result = await _verifyPin(event.pin);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (isCorrect) async {
        if (isCorrect) {
          emit(const AuthSuccess('Unlocked!'));
        } else {
          final updatedLockout = await _authRepository.getLockoutRemainingSeconds();
          final remaining = updatedLockout.getOrElse((_) => 0);
          if (remaining > 0) {
            emit(AuthLockoutState(remaining));
          } else {
            emit(const AuthError('Incorrect PIN. Please try again.'));
          }
        }
      },
    );
  }

  Future<void> _onBiometricAuth(BiometricAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.authenticateWithBiometrics();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (authenticated) {
        if (authenticated) {
          emit(const AuthSuccess('Unlocked via biometrics!'));
        } else {
          emit(const AuthError('Biometric authentication cancelled.'));
        }
      },
    );
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _checkAuthStatus();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (hasPin) {
        if (hasPin) {
          emit(const AuthSuccess('PIN exists'));
        } else {
          emit(const AuthError('No PIN found'));
        }
      },
    );
  }

  Future<void> _onClearPin(ClearPinEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _clearPin();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthPinCleared()),
    );
  }
}
