import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'auth/login_screen.dart';
import 'app_shell.dart';

/// Listens to [AuthService] state and routes to the correct screen:
///   - Not signed in → LoginScreen
///   - Signed in, loading → splash
///   - Signed in → role-specific dashboard
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    if (auth.isLoading) {
      return const _SplashScreen();
    }

    if (!auth.isSignedIn) {
      return const LoginScreen();
    }

    return _buildDashboard(auth.currentUser!);
  }

  Widget _buildDashboard(AppUser user) {
    return AppShell(currentUser: user);
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('eHadir', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
