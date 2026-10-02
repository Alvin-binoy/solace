import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/pin_pad.dart';

class LockScreenPage extends StatelessWidget {
  const LockScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<AuthBloc>(),
      child: const _LockScreenView(),
    );
  }
}

class _LockScreenView extends StatefulWidget {
  const _LockScreenView();

  @override
  State<_LockScreenView> createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<_LockScreenView> {
  String _pin = '';
  int _remainingLockoutSeconds = 0;
  Timer? _lockoutTimer;

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    setState(() {
      _remainingLockoutSeconds = seconds;
      _pin = '';
    });
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingLockoutSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingLockoutSeconds = 0);
      } else {
        setState(() => _remainingLockoutSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _onNumberTapped(String number) {
    if (_remainingLockoutSeconds > 0) return;
    if (_pin.length < 4) {
      setState(() => _pin += number);
      if (_pin.length == 4) {
        context.read<AuthBloc>().add(VerifyPinEvent(_pin));
      }
    }
  }

  void _onBackspace() {
    if (_remainingLockoutSeconds > 0) return;
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              context.go(RouteNames.dashboard);
            } else if (state is AuthPinCleared) {
              context.go(RouteNames.setupPin);
            } else if (state is AuthLockoutState) {
              _startLockoutTimer(state.remainingSeconds);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
              setState(() => _pin = '');
            }
          },
          builder: (context, state) {
            final isLockedOut = _remainingLockoutSeconds > 0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Icon(
                  isLockedOut ? Icons.lock_clock_outlined : Icons.lock_outline,
                  size: 64,
                  color: isLockedOut ? Colors.red : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  isLockedOut
                      ? 'Too many failed attempts!\nTry again in $_remainingLockoutSeconds seconds.'
                      : 'Enter your PIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: isLockedOut ? Colors.red : null,
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),

                const Spacer(),

                if (state is AuthLoading)
                  const CircularProgressIndicator()
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: PinPad(
                      onNumberTapped: _onNumberTapped,
                      onBackspaceTapped: _onBackspace,
                    ),
                  ),
                  const SizedBox(height: 16),
                  IconButton(
                    icon: const Icon(Icons.fingerprint, size: 40),
                    tooltip: 'Unlock with Biometrics',
                    onPressed: isLockedOut
                        ? null
                        : () => context.read<AuthBloc>().add(const BiometricAuthEvent()),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.read<AuthBloc>().add(const ClearPinEvent()),
                  child: const Text('Reset PIN (Wipes Data)'),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}
