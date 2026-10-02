import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'core/theme/app_theme.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/overdue_checker_service.dart';
import 'features/tasks/presentation/bloc/task_bloc.dart';
import 'features/tasks/presentation/bloc/task_event.dart';

// We keep a reference to the listener so it stays alive
late final AppLifecycleListener _lifecycleListener;

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set up dependency injection
  configureDependencies();

  // Run the overdue check immediately on app start
  GetIt.I<OverdueCheckerService>().checkNow();

  // Listen for the app coming back to the foreground (e.g., from home screen)
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
      child: MaterialApp.router(
        title: 'Solace',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
      ),
    );
  }
}