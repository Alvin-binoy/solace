import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/setup_pin_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart';
import '../../features/tasks/presentation/pages/create_edit_task_page.dart';
import '../../features/journal/presentation/pages/journal_entry_page.dart';
import '../../features/journal/presentation/pages/journal_view_page.dart';
import '../../features/journal/domain/entities/journal_entry_entity.dart';
import '../../features/journal/presentation/bloc/journal_bloc.dart';
import '../../features/journal/presentation/bloc/journal_event.dart';
import 'main_shell.dart';
import 'route_names.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: RouteNames.setupPin,
      builder: (context, state) => const SetupPinPage(),
    ),
    GoRoute(
      path: RouteNames.lock,
      builder: (context, state) => const LockScreenPage(),
    ),

    // NEW: The single unified route that holds our swipeable PageView
    GoRoute(
      path: RouteNames.dashboard, // Kept this path string so auth redirects don't break
      builder: (context, state) => const MainShell(),
    ),

    GoRoute(
      path: RouteNames.taskCreate,
      builder: (context, state) => const CreateEditTaskPage(),
    ),
    GoRoute(
      path: '/journal-entry',
      builder: (context, state) {
        final entry = state.extra as JournalEntryEntity?;
        return BlocProvider(
          create: (context) => GetIt.I<JournalBloc>(),
          child: JournalEntryPage(existingEntry: entry),
        );
      },
    ),
    GoRoute(
      path: '/journal-view/:id',
      builder: (context, state) {
        final entryId = state.pathParameters['id']!;
        return BlocProvider(
          create: (context) => GetIt.I<JournalBloc>()..add(WatchEntriesEvent()),
          child: JournalViewPage(entryId: entryId),
        );
      },
    ),
    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);