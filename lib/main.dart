import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/overdue_checker_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_worker.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_event.dart';
import 'features/settings/presentation/bloc/settings_state.dart';

late final AppLifecycleListener _lifecycleListener;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  await Workmanager().registerPeriodicTask(
    'solace_overdue_checker_task_id',
    'checkOverdueTasks',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.notRequired),
  );

  await NotificationService().init();
  await NotificationService().requestPermissions();

  configureDependencies();
  GetIt.I<OverdueCheckerService>().checkNow();

  _lifecycleListener = AppLifecycleListener(
    onResume: () => GetIt.I<OverdueCheckerService>().checkNow(),
  );

  runApp(const SolaceApp());
}

class SolaceApp extends StatelessWidget {
  const SolaceApp({super.key});

  ThemeMode _getThemeMode(String themeString) {
    switch (themeString) {
      case 'light': return ThemeMode.light;
      case 'dark': return ThemeMode.dark;
      default: return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.I<TaskBloc>()..add(WatchTasksEvent())),
        BlocProvider(create: (_) => GetIt.I<SettingsBloc>()..add(LoadSettingsEvent())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          ThemeMode currentMode = ThemeMode.system;
          if (state is SettingsLoaded) {
            currentMode = _getThemeMode(state.settings.themeMode);
          }

          return MaterialApp.router(
            title: 'Solace',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: currentMode,
            routerConfig: appRouter,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              quill.FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', 'US')],
          );
        },
      ),
    );
  }
}