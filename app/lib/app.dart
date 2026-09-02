import 'package:flutter/material.dart';

/// Root application widget. Routing and theme grow here as features land.
class VrijdagApp extends StatelessWidget {
  const VrijdagApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vrijdag',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF55624A),
          brightness: Brightness.light,
          surface: const Color(0xFFEFEBE2),
        ),
        useMaterial3: true,
      ),
      home: const _BootstrapScreen(),
    );
  }
}

/// Temporary host screen until F-002 / Day view exist.
/// Not product UI — proves the app boots under Riverpod.
class _BootstrapScreen extends StatelessWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vrijdag',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF221F1A),
                ),
              ),
              const SizedBox(height: 13),
              Text(
                'Technical foundation (F-001). Calendar screens arrive after design Task 02.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF56504A),
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                'Environment scaffold ready.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F6858),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
