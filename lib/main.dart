import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // NEW: Required for Quill
import 'package:flutter_quill/flutter_quill.dart' as quill; // NEW: Required for Quill localizations

import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/overdue_checker_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_worker.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

late final AppLifecycleListener _lifecycleListener;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  await Workmanager().registerPeriodicTask(
    'solace_overdue_checker_task_id',
    'checkOverdueTasks',
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.notRequired,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );

  await NotificationService().init();
  await NotificationService().requestPermissions();

  configureDependencies();
  GetIt.I<OverdueCheckerService>().checkNow();

  _lifecycleListener = AppLifecycleListener(
    onResume: () {
      GetIt.I<OverdueCheckerService>().checkNow();
    },
  );

  runApp(const SolaceApp());
}

class SolaceApp extends StatelessWidget {
  const SolaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<TaskBloc>()..add(WatchTasksEvent()),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (_, ThemeMode currentMode, __) {
          return MaterialApp.router(
            title: 'Solace',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: currentMode,
            routerConfig: appRouter,
            // EDGE CASE HANDLED: Added localizations to prevent Quill crashes
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              quill.FlutterQuillLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', 'US'),
            ],
          );
        },
      ),
    );
  }
}