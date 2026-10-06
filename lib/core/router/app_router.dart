import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/setup_pin_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart';
import '../../features/tasks/presentation/pages/dashboard_page.dart';
import '../../features/tasks/presentation/pages/task_list_page.dart';
import '../../features/tasks/presentation/pages/create_edit_task_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/journal_entry_page.dart';
import '../../features/journal/presentation/pages/journal_view_page.dart'; // NEW
import '../../features/journal/domain/entities/journal_entry_entity.dart';
import '../../features/journal/presentation/bloc/journal_bloc.dart';
import '../../features/journal/presentation/bloc/journal_event.dart'; // NEW
import '../../features/calendar/presentation/pages/calendar_page.dart';
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
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: RouteNames.dashboard,
          builder: (context, state) => const DashboardPage(),
        ),
        GoRoute(
          path: RouteNames.tasks,
          builder: (context, state) => const TaskListPage(),
        ),
        GoRoute(
          path: RouteNames.schedule,
          builder: (context, state) => const SchedulePage(),
        ),
        GoRoute(
          path: RouteNames.journal,
          builder: (context, state) => const JournalPage(),
        ),
        GoRoute(
          path: RouteNames.calendar,
          builder: (context, state) => const CalendarPage(),
        ),
      ],
    ),
    GoRoute(
      path: RouteNames.taskCreate,
      builder: (context, state) => const CreateEditTaskPage(),
    ),
    // Editor Page
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
    // NEW: Read-Only View Page
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
  ],
);