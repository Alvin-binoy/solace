import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../domain/use_cases/check_auth_status_use_case.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkRoute();
  }

  Future<void> _checkRoute() async {
    // Directly call the use case via GetIt
    final checkAuthStatus = GetIt.I<CheckAuthStatusUseCase>();
    final result = await checkAuthStatus();

    if (!mounted) return;

    result.fold(
          (failure) => context.go(RouteNames.setupPin), // Fallback to setup if error
          (hasPin) {
        if (hasPin) {
          context.go(RouteNames.lock); // Returning user -> Lock screen
        } else {
          context.go(RouteNames.setupPin); // First launch -> Setup PIN
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}