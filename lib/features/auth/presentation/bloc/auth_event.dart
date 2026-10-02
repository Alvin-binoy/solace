import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

class SetupPinEvent extends AuthEvent {
  final String pin;
  const SetupPinEvent(this.pin);
  @override
  List<Object> get props => [pin];
}

class VerifyPinEvent extends AuthEvent {
  final String pin;
  const VerifyPinEvent(this.pin);
  @override
  List<Object> get props => [pin];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class ClearPinEvent extends AuthEvent {
  const ClearPinEvent();
}