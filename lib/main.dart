import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SolaceApp());
}

class SolaceApp extends StatelessWidget {
  const SolaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solace',
      debugShowCheckedModeBanner: false, // Removes the red debug banner
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system, // Automatically adapts to user's phone setting
      home: const Scaffold(
        body: Center(
          child: Text('Solace App Ready!'),
        ),
      ),
    );
  }
}