import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/shared_prefs_service.dart';
import '../services/user_profile_service.dart';

class AuthService {
  final supabase = SupabaseConfig.supabase;
  final _userProfileService = UserProfileService();

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    print('Attempting to sign up with email: $email'); // Debug log

    try {
      final response = await supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      print('Sign up response: ${response.user?.id}'); // Debug log

      // Create user profile after successful signup
      if (response.user != null) {
        print('Creating user profile...'); // Debug log
        try {
          await _userProfileService.createUserProfile(
            userId: response.user!.id,
            email: response.user!.email!,
            fullName: fullName,
          );
          print('User profile created successfully'); // Debug log
        } catch (e) {
          // Profile creation failed, but signup was successful
          // This might happen if the trigger already created the profile
          print('Profile creation failed or already exists: $e');
        }
      }

      return response;
    } catch (e) {
      print('Sign up error: $e'); // Debug log
      rethrow; // Re-throw to be handled by UI
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('Attempting to sign in with email: $email'); // Debug log

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      print('Sign in response: ${response.user?.id}'); // Debug log

      // Save user session
      if (response.user != null && response.session != null) {
        await SharedPrefsService.saveUserSession(
          userId: response.user!.id,
          email: response.user!.email!,
          session: response.session!.accessToken,
        );

        print('User session saved successfully'); // Debug log

        // Ensure user profile exists
        try {
          await _userProfileService.getOrCreateUserProfile(
            userId: response.user!.id,
            email: response.user!.email!,
          );
          print('User profile ensured'); // Debug log
        } catch (profileError) {
          print('Profile creation/retrieval error: $profileError');
          // Don't fail the login if profile creation fails
        }
      }

      return response;
    } catch (e) {
      print('Sign in error: $e'); // Debug log
      rethrow; // Re-throw to be handled by UI
    }
  }

  // Sign out
  Future<void> signOut() async {
    await supabase.auth.signOut();
    await SharedPrefsService.clearUserSession();
  }

  // Get current user
  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  // Restore session if user is already logged in
  Future<void> restoreSession() async {
    final isLoggedIn = await SharedPrefsService.isUserLoggedIn();
    if (isLoggedIn) {
      final session = await SharedPrefsService.getSession();
      if (session != null) {
        try {
          // Check if current session is still valid
          final currentUser = supabase.auth.currentUser;
          if (currentUser == null) {
            // Session expired, clear it
            await SharedPrefsService.clearUserSession();
          }
        } catch (e) {
          // Session expired, clear it
          await SharedPrefsService.clearUserSession();
        }
      }
    }
  }
}
