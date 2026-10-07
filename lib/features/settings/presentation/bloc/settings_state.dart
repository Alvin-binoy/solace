import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings_entity.dart';

sealed class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final AppSettingsEntity settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object> get props => [settings];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object> get props => [message];
}

// Temporary states for backup actions
class SettingsBackupReady extends SettingsState {
  final Uint8List bytes;
  const SettingsBackupReady(this.bytes);
  @override
  List<Object> get props => [bytes];
}

class SettingsRestoreSuccess extends SettingsState {}

class SettingsActionError extends SettingsState {
  final String message;
  const SettingsActionError(this.message);
  @override
  List<Object> get props => [message];
}