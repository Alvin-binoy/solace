// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:solace/core/database/app_database.dart' as _i844;
import 'package:solace/core/database/daos/journal_dao.dart' as _i57;
import 'package:solace/core/di/external_module.dart' as _i951;
import 'package:solace/core/services/overdue_checker_service.dart' as _i546;
import 'package:solace/features/auth/data/datasources/secure_storage_datasource.dart'
    as _i571;
import 'package:solace/features/auth/data/repositories/auth_repository_impl.dart'
    as _i37;
import 'package:solace/features/auth/domain/repositories/auth_repository.dart'
    as _i558;
import 'package:solace/features/auth/domain/use_cases/check_auth_status_use_case.dart'
    as _i888;
import 'package:solace/features/auth/domain/use_cases/clear_pin_use_case.dart'
    as _i176;
import 'package:solace/features/auth/domain/use_cases/setup_pin_use_case.dart'
    as _i413;
import 'package:solace/features/auth/domain/use_cases/verify_pin_use_case.dart'
    as _i834;
import 'package:solace/features/auth/presentation/bloc/auth_bloc.dart' as _i601;
import 'package:solace/features/journal/data/datasources/journal_local_datasource.dart'
    as _i220;
import 'package:solace/features/journal/data/repositories/journal_repository_impl.dart'
    as _i445;
import 'package:solace/features/journal/domain/repositories/journal_repository.dart'
    as _i924;
import 'package:solace/features/journal/domain/use_cases/add_entry_use_case.dart'
    as _i949;
import 'package:solace/features/journal/domain/use_cases/delete_entry_use_case.dart'
    as _i382;
import 'package:solace/features/journal/domain/use_cases/get_entry_by_id_use_case.dart'
    as _i972;
import 'package:solace/features/journal/domain/use_cases/update_entry_use_case.dart'
    as _i767;
import 'package:solace/features/journal/domain/use_cases/watch_all_entries_use_case.dart'
    as _i811;
import 'package:solace/features/journal/presentation/bloc/journal_bloc.dart'
    as _i159;
import 'package:solace/features/tasks/data/datasources/task_local_datasource.dart'
    as _i493;
import 'package:solace/features/tasks/data/repositories/task_repository_impl.dart'
    as _i690;
import 'package:solace/features/tasks/domain/repositories/task_repository.dart'
    as _i294;
import 'package:solace/features/tasks/domain/use_cases/add_task_use_case.dart'
    as _i635;
import 'package:solace/features/tasks/domain/use_cases/delete_task_use_case.dart'
    as _i847;
import 'package:solace/features/tasks/domain/use_cases/update_task_use_case.dart'
    as _i111;
import 'package:solace/features/tasks/domain/use_cases/watch_all_tasks_use_case.dart'
    as _i1000;
import 'package:solace/features/tasks/presentation/bloc/task_bloc.dart'
    as _i154;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final externalModule = _$ExternalModule();
    gh.singleton<_i558.FlutterSecureStorage>(
      () => externalModule.secureStorage,
    );
    gh.lazySingleton<_i844.AppDatabase>(() => _i844.AppDatabase());
    gh.lazySingleton<_i493.TaskLocalDatasource>(
      () => _i493.TaskLocalDatasourceImpl(gh<_i844.AppDatabase>()),
    );
    gh.lazySingleton<_i571.SecureStorageDatasource>(
      () => _i571.SecureStorageDatasourceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i57.JournalDao>(
      () => _i57.JournalDao(gh<_i844.AppDatabase>()),
    );
    gh.factory<_i558.AuthRepository>(
      () => _i37.AuthRepositoryImpl(gh<_i571.SecureStorageDatasource>()),
    );
    gh.factory<_i888.CheckAuthStatusUseCase>(
      () => _i888.CheckAuthStatusUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i176.ClearPinUseCase>(
      () => _i176.ClearPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i413.SetupPinUseCase>(
      () => _i413.SetupPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i834.VerifyPinUseCase>(
      () => _i834.VerifyPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i294.TaskRepository>(
      () => _i690.TaskRepositoryImpl(gh<_i493.TaskLocalDatasource>()),
    );
    gh.lazySingleton<_i546.OverdueCheckerService>(
      () => _i546.OverdueCheckerService(gh<_i294.TaskRepository>()),
    );
    gh.factory<_i635.AddTaskUseCase>(
      () => _i635.AddTaskUseCase(gh<_i294.TaskRepository>()),
    );
    gh.factory<_i847.DeleteTaskUseCase>(
      () => _i847.DeleteTaskUseCase(gh<_i294.TaskRepository>()),
    );
    gh.factory<_i111.UpdateTaskUseCase>(
      () => _i111.UpdateTaskUseCase(gh<_i294.TaskRepository>()),
    );
    gh.factory<_i1000.WatchAllTasksUseCase>(
      () => _i1000.WatchAllTasksUseCase(gh<_i294.TaskRepository>()),
    );
    gh.factory<_i601.AuthBloc>(
      () => _i601.AuthBloc(
        gh<_i413.SetupPinUseCase>(),
        gh<_i834.VerifyPinUseCase>(),
        gh<_i888.CheckAuthStatusUseCase>(),
        gh<_i176.ClearPinUseCase>(),
        gh<_i558.AuthRepository>(),
      ),
    );
    gh.lazySingleton<_i220.JournalLocalDatasource>(
      () => _i220.JournalLocalDatasourceImpl(gh<_i57.JournalDao>()),
    );
    gh.factory<_i154.TaskBloc>(
      () => _i154.TaskBloc(
        gh<_i1000.WatchAllTasksUseCase>(),
        gh<_i635.AddTaskUseCase>(),
        gh<_i111.UpdateTaskUseCase>(),
        gh<_i847.DeleteTaskUseCase>(),
      ),
    );
    gh.factory<_i924.JournalRepository>(
      () => _i445.JournalRepositoryImpl(gh<_i220.JournalLocalDatasource>()),
    );
    gh.factory<_i949.AddEntryUseCase>(
      () => _i949.AddEntryUseCase(gh<_i924.JournalRepository>()),
    );
    gh.factory<_i382.DeleteEntryUseCase>(
      () => _i382.DeleteEntryUseCase(gh<_i924.JournalRepository>()),
    );
    gh.factory<_i972.GetEntryByIdUseCase>(
      () => _i972.GetEntryByIdUseCase(gh<_i924.JournalRepository>()),
    );
    gh.factory<_i767.UpdateEntryUseCase>(
      () => _i767.UpdateEntryUseCase(gh<_i924.JournalRepository>()),
    );
    gh.factory<_i811.WatchAllEntriesUseCase>(
      () => _i811.WatchAllEntriesUseCase(gh<_i924.JournalRepository>()),
    );
    gh.factory<_i159.JournalBloc>(
      () => _i159.JournalBloc(
        gh<_i811.WatchAllEntriesUseCase>(),
        gh<_i949.AddEntryUseCase>(),
        gh<_i767.UpdateEntryUseCase>(),
        gh<_i382.DeleteEntryUseCase>(),
      ),
    );
    return this;
  }
}

class _$ExternalModule extends _i951.ExternalModule {}
