import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';

class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);

    final authService = ref.watch(authServiceProvider);

    void signIn() async {
      // Validate inputs
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        return;
      }

      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(emailController.text)) {
        errorMessage.value = 'Please enter a valid email';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        final response = await authService.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.user != null) {
          // Update current user
          ref.read(currentUserProvider.notifier).state = response.user!.id;

          if (context.mounted) {
            context.go('/home');
          }
        } else {
          errorMessage.value = 'Login failed. Please check your credentials.';
        }
      } catch (e) {
        print('Sign in error: $e'); // Debug log

        String errorMsg = 'Login failed';
        // Improved error message handling, especially for unconfirmed emails
        if (e.toString().contains('Invalid login credentials')) {
          errorMsg = 'Invalid email or password';
        } else if (e.toString().contains('Email not confirmed') ||
            e.toString().contains('not confirmed') ||
            e.toString().contains('confirmation required')) {
          errorMsg =
              'Your email address has not been confirmed yet. Please check your inbox and click the confirmation link we sent you. If you need a new confirmation email, try signing up again.';
        } else if (e.toString().contains('Too many requests')) {
          errorMsg = 'Too many login attempts. Please try again later.';
        } else if (e.toString().contains('Network')) {
          errorMsg = 'Network error. Please check your connection.';
        } else {
          // Avoid exposing raw errors to the user
          print('Detailed error: $e'); // Keep detailed error in logs only
          errorMsg = 'Login failed. Please try again or contact support.';
        }

        errorMessage.value = errorMsg;
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (errorMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage.value!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                      // Display resend confirmation option only for unconfirmed email errors
                      if (errorMessage.value!.contains(
                        'has not been confirmed',
                      ))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // In the future, implement resend confirmation functionality
                                  // For now, direct users to sign up again
                                  context.go('/signup');
                                },
                                child: const Text('Go to Sign Up'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red.shade800,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading.value ? null : signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Sign In', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/signup'),
                child: const Text("Don't have an account? Sign Up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
