// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:solace/core/di/external_module.dart' as _i951;
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
    gh.lazySingleton<_i571.SecureStorageDatasource>(
      () => _i571.SecureStorageDatasourceImpl(gh<_i558.FlutterSecureStorage>()),
    );
    gh.factory<_i558.AuthRepository>(
      () => _i37.AuthRepositoryImpl(gh<_i571.SecureStorageDatasource>()),
    );
    gh.factory<_i413.SetupPinUseCase>(
      () => _i413.SetupPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i834.VerifyPinUseCase>(
      () => _i834.VerifyPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i888.CheckAuthStatusUseCase>(
      () => _i888.CheckAuthStatusUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i176.ClearPinUseCase>(
      () => _i176.ClearPinUseCase(gh<_i558.AuthRepository>()),
    );
    gh.factory<_i601.AuthBloc>(
      () => _i601.AuthBloc(
        gh<_i413.SetupPinUseCase>(),
        gh<_i834.VerifyPinUseCase>(),
        gh<_i888.CheckAuthStatusUseCase>(),
        gh<_i176.ClearPinUseCase>(),
      ),
    );
    return this;
  }
}

class _$ExternalModule extends _i951.ExternalModule {}
