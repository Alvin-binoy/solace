import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import '../../domain/entities/app_settings_entity.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object> get props => [];
}

class LoadSettingsEvent extends SettingsEvent {}

class UpdateSettingsEvent extends SettingsEvent {
  final AppSettingsEntity settings;
  const UpdateSettingsEvent(this.settings);
  @override
  List<Object> get props => [settings];
}

class CreateBackupEvent extends SettingsEvent {
  final String password;
  const CreateBackupEvent(this.password);
  @override
  List<Object> get props => [password];
}

class RestoreBackupEvent extends SettingsEvent {
  final Uint8List backupBytes;
  final String password;
  const RestoreBackupEvent(this.backupBytes, this.password);
  @override
  List<Object> get props => [backupBytes, password];
}