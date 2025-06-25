import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/shared_prefs_service.dart';

class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _checkInitialRoute(context, ref);
      });
      return null;
    }, []);

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.amber),
            SizedBox(height: 16),
            Text(
              'My Recipes',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  Future<void> _checkInitialRoute(BuildContext context, WidgetRef ref) async {
    try {
      // Check if first launch
      final isFirstLaunch = await SharedPrefsService.isFirstLaunch();

      if (isFirstLaunch) {
        if (context.mounted) {
          context.go('/get-started');
        }
        return;
      }

      // Check if user is logged in
      final isLoggedIn = await SharedPrefsService.isUserLoggedIn();
      final authService = ref.read(authServiceProvider);

      if (isLoggedIn) {
        // Try to restore session
        await authService.restoreSession();
        final user = authService.getCurrentUser();

        if (user != null) {
          // Set current user and go to home
          ref.read(currentUserProvider.notifier).state = user.id;
          if (context.mounted) {
            context.go('/home');
          }
        } else {
          // Session expired, go to signin
          if (context.mounted) {
            context.go('/signin');
          }
        }
      } else {
        // Not logged in, go to signin
        if (context.mounted) {
          context.go('/signin');
        }
      }
    } catch (e) {
      // On error, go to signin
      if (context.mounted) {
        context.go('/signin');
      }
    }
  }
}
