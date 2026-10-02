import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/setup_pin_page.dart';
import '../../features/auth/presentation/pages/lock_screen_page.dart'; // <-- Add this import
import 'route_names.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) => const SplashPage(), // <-- Make sure this is here
    ),
    GoRoute(
      path: RouteNames.setupPin,
      builder: (context, state) => const SetupPinPage(),
    ),
    GoRoute(
      path: RouteNames.lock,
      builder: (context, state) => const LockScreenPage(),
    ),
    GoRoute(
      path: RouteNames.dashboard,
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Dashboard (Stage 4)')),
      ),
    ),
  ],
);