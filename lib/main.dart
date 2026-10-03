import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/overdue_checker_service.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';

// NEW: Global ValueNotifier to easily toggle themes from anywhere
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark); // Defaulting to dark mode to match your vibe!

late final AppLifecycleListener _lifecycleListener;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
      // NEW: ValueListenableBuilder listens to themeNotifier and rebuilds the app when changed
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
          );
        },
      ),
    );
  }
}