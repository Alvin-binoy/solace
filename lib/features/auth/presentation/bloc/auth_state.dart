import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String message;
  const AuthSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

class AuthLockoutState extends AuthState {
  final int remainingSeconds;
  const AuthLockoutState(this.remainingSeconds);
  @override
  List<Object> get props => [remainingSeconds];
}

class AuthPinCleared extends AuthState {}
