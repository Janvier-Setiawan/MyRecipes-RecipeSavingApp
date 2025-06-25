import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';

class SignUpScreen extends HookConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullNameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final successMessage = useState<String?>(null);
    final hasSignedUp = useState(false);

    final authService = ref.watch(authServiceProvider);

    void signUp() async {
      // Validate inputs
      if (fullNameController.text.isEmpty ||
          emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        errorMessage.value = 'Please fill in all fields';
        return;
      }

      if (!RegExp(
        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      ).hasMatch(emailController.text)) {
        errorMessage.value = 'Please enter a valid email';
        return;
      }

      if (passwordController.text.length < 6) {
        errorMessage.value = 'Password must be at least 6 characters';
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        errorMessage.value = 'Passwords do not match';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        print(
          'Attempting to sign up with email: ${emailController.text}',
        ); // Debug log

        final response = await authService.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          fullName: fullNameController.text.trim().isEmpty
              ? null
              : fullNameController.text.trim(),
        );

        print('Sign up response: ${response.user?.id}'); // Debug log

        if (response.user != null) {
          print('User created successfully'); // Debug log

          // Show success message and instructions instead of auto-signing in
          errorMessage.value = null;
          hasSignedUp.value = true;
          successMessage.value =
              'Account created successfully! Please check your email to confirm your account before signing in.';

          // Clear the form
          fullNameController.clear();
          emailController.clear();
          passwordController.clear();
          confirmPasswordController.clear();
        } else {
          errorMessage.value = 'Sign up failed. Please try again.';
        }
      } catch (e) {
        print('Sign up error: $e'); // Debug log

        String errorMsg = 'Sign up failed';
        if (e.toString().contains('User already registered')) {
          errorMsg = 'Email already registered. Please sign in instead.';
        } else if (e.toString().contains('Password should be at least')) {
          errorMsg = 'Password must be at least 6 characters long';
        } else if (e.toString().contains('Unable to validate email')) {
          errorMsg = 'Invalid email format';
        } else if (e.toString().contains('Network')) {
          errorMsg = 'Network error. Please check your connection.';
        } else {
          // Avoid exposing raw errors to the user
          print('Detailed error: $e'); // Keep detailed error in logs only
          errorMsg = 'Sign up failed. Please try again or contact support.';
        }

        errorMessage.value = errorMsg;
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Create Account',
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
                  child: Row(
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
                ),
              if (successMessage.value != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: Colors.green.shade800,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              successMessage.value!,
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/signin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Go to Sign In'),
                      ),
                    ],
                  ),
                ),
              if (!hasSignedUp.value) ...[
                TextFormField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: isLoading.value ? null : signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
