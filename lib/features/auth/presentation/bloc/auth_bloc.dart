import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/use_cases/check_auth_status_use_case.dart';
import '../../domain/use_cases/setup_pin_use_case.dart';
import '../../domain/use_cases/verify_pin_use_case.dart';
import '../../domain/use_cases/clear_pin_use_case.dart'; // <-- Added import
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SetupPinUseCase _setupPin;
  final VerifyPinUseCase _verifyPin;
  final CheckAuthStatusUseCase _checkAuthStatus;
  final ClearPinUseCase _clearPin; // <-- Added use case

  AuthBloc(
      this._setupPin,
      this._verifyPin,
      this._checkAuthStatus,
      this._clearPin, // <-- Added to constructor
      ) : super(AuthInitial()) {
    on<SetupPinEvent>(_onSetupPin);
    on<VerifyPinEvent>(_onVerifyPin);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ClearPinEvent>(_onClearPin); // <-- Registered event
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
    final result = await _verifyPin(event.pin);

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (isCorrect) {
        if (isCorrect) {
          emit(const AuthSuccess('Unlocked!'));
        } else {
          emit(const AuthError('Incorrect PIN. Please try again.'));
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

  // <-- Added handler method
  Future<void> _onClearPin(ClearPinEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _clearPin();

    result.fold(
          (failure) => emit(AuthError(failure.message)),
          (_) => emit(AuthPinCleared()),
    );
  }
}