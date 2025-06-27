import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/app_providers.dart';
import '../config/app_theme.dart';

class SignInScreen extends HookConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final isPasswordVisible = useState(false);

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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF8F0), // Light peach
                  Color(0xFFFFEFE7), // Lighter peach
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // App Logo and Title
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 60,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome Back!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Text(
                    'Sign in to continue your culinary journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Error Message
                  if (errorMessage.value != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              errorMessage.value!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Form Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'Enter your email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                isPasswordVisible.value
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                isPasswordVisible.value =
                                    !isPasswordVisible.value;
                              },
                            ),
                            filled: true,
                            fillColor: AppTheme.surfaceColor,
                          ),
                          obscureText: !isPasswordVisible.value,
                        ),
                        const SizedBox(height: 32),

                        // Sign In Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading.value ? null : signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                            child: isLoading.value
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/signup'),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
