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

  void _onNumberTapped(String number) {
    if (_pin.length < 4) {
      setState(() => _pin += number);
      if (_pin.length == 4) {
        // Trigger the verification Use Case!
        context.read<AuthBloc>().add(VerifyPinEvent(_pin));
      }
    }
  }

  void _onBackspace() {
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
              // PIN is correct! Let them into the app.
              context.go(RouteNames.dashboard);
            }else if (state is AuthPinCleared) { // <-- Add this check
              context.go(RouteNames.setupPin);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
              setState(() => _pin = ''); // Clear PIN to try again
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Enter your PIN', style: TextStyle(fontSize: 20)),
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
                            : Colors.grey.withOpacity(0.3),
                      ),
                    );
                  }),
                ),

                const Spacer(),

                if (state is AuthLoading)
                  const CircularProgressIndicator()
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: PinPad(
                      onNumberTapped: _onNumberTapped,
                      onBackspaceTapped: _onBackspace,
                    ),
                  ),
                const SizedBox(height: 48),
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