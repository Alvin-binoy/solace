import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/use_cases/watch_settings_use_case.dart';
import '../../domain/use_cases/update_settings_use_case.dart';
import '../../domain/use_cases/create_backup_use_case.dart';
import '../../domain/use_cases/restore_backup_use_case.dart';
import 'settings_event.dart';
import 'settings_state.dart';

@injectable
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final WatchSettingsUseCase _watchSettings;
  final UpdateSettingsUseCase _updateSettings;
  final CreateBackupUseCase _createBackup;
  final RestoreBackupUseCase _restoreBackup;

  SettingsBloc(
      this._watchSettings,
      this._updateSettings,
      this._createBackup,
      this._restoreBackup,
      ) : super(SettingsInitial()) {
    on<LoadSettingsEvent>(_onLoadSettings);
    on<UpdateSettingsEvent>(_onUpdateSettings);
    on<CreateBackupEvent>(_onCreateBackup);
    on<RestoreBackupEvent>(_onRestoreBackup);
  }

  Future<void> _onLoadSettings(LoadSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());

    await emit.forEach<Either<Failure, AppSettingsEntity>>(
      _watchSettings(),
      onData: (result) => result.fold(
            (failure) => SettingsError(failure.message),
            (settings) => SettingsLoaded(settings),
      ),
      onError: (_, __) => const SettingsError('An unexpected error occurred loading settings.'),
    );
  }

  Future<void> _onUpdateSettings(UpdateSettingsEvent event, Emitter<SettingsState> emit) async {
    await _updateSettings(event.settings);
  }

  Future<void> _onCreateBackup(CreateBackupEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    final result = await _createBackup(event.password);

    result.fold(
          (failure) => emit(SettingsActionError(failure.message)),
          (bytes) => emit(SettingsBackupReady(bytes)),
    );

    // Resume listening to settings after the one-off action completes
    add(LoadSettingsEvent());
  }

  Future<void> _onRestoreBackup(RestoreBackupEvent event, Emitter<SettingsState> emit) async {
    emit(SettingsLoading());
    final result = await _restoreBackup(event.backupBytes, event.password);

    result.fold(
          (failure) => emit(SettingsActionError(failure.message)),
          (_) => emit(SettingsRestoreSuccess()),
    );

    add(LoadSettingsEvent());
  }
}