import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/pin_pad.dart';

class SetupPinPage extends StatelessWidget {
  const SetupPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We wrap the page in BlocProvider so it has access to our AuthBloc
    return BlocProvider(
      create: (_) => GetIt.I<AuthBloc>(),
      child: const _SetupPinView(),
    );
  }
}

class _SetupPinView extends StatefulWidget {
  const _SetupPinView();

  @override
  State<_SetupPinView> createState() => _SetupPinViewState();
}

class _SetupPinViewState extends State<_SetupPinView> {
  String _pin = '';

  void _onNumberTapped(String number) {
    if (_pin.length < 4) {
      setState(() => _pin += number);
      if (_pin.length == 4) {
        // We have 4 digits, tell the BLoC to save it!
        context.read<AuthBloc>().add(SetupPinEvent(_pin));
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.green),
              );
              context.go(RouteNames.dashboard);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
              setState(() => _pin = ''); // Reset PIN on error
            }
          },
          builder: (context, state) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text('Create a 4-digit PIN', style: TextStyle(fontSize: 20)),
                const SizedBox(height: 32),

                // Show 4 dots for the PIN
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

                // Show loading spinner or the Pin Pad
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
              ],
            );
          },
        ),
      ),
    );
  }
}