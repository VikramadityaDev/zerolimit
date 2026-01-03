import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerolimit/providers/startup_provider.dart';
import 'package:zerolimit/screens/home_src.dart';
import 'package:zerolimit/screens/login_scr.dart';

class StartUp extends ConsumerWidget {
  const StartUp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startupState = ref.watch(startupProvider);

    return startupState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const LoginScreen(),
      data: (token) =>
      token.isEmpty ? const LoginScreen() : const HomeScreen(),
    );
  }
}
