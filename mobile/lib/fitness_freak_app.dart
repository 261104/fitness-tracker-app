import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/shell/main_shell.dart';
import 'providers/providers.dart';

class FitnessFreakApp extends ConsumerWidget {
  const FitnessFreakApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: auth.when(
        data: (user) =>
            user == null ? const SignInScreen() : const MainShell(),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: AppColors.purple),
          ),
        ),
        error: (_, __) => const SignInScreen(),
      ),
    );
  }
}
