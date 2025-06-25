import 'dart:typed_data';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class UserProfileService {
  final supabase = SupabaseConfig.supabase;

  // Get user profile by user ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Profile might not exist yet
      return null;
    }
  }

  // Create user profile (usually called after signup)
  Future<UserProfile> createUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? username,
  }) async {
    final profileData = {
      'user_id': userId,
      'email': email,
      'full_name': fullName ?? email.split('@')[0],
      'username': username,
      'cooking_level': 'beginner',
      'dietary_preferences': <String>[],
    };

    final response = await supabase
        .from('user_profiles')
        .insert(profileData)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Update user profile
  Future<UserProfile> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? cookingLevel,
    String? favoriteCuisine,
    List<String>? dietaryPreferences,
  }) async {
    final updateData = <String, dynamic>{};

    if (fullName != null) updateData['full_name'] = fullName;
    if (username != null) updateData['username'] = username;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
    if (bio != null) updateData['bio'] = bio;
    if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
    if (dateOfBirth != null) {
      updateData['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
    }
    if (cookingLevel != null) updateData['cooking_level'] = cookingLevel;
    if (favoriteCuisine != null)
      updateData['favorite_cuisine'] = favoriteCuisine;
    if (dietaryPreferences != null)
      updateData['dietary_preferences'] = dietaryPreferences;

    final response = await supabase
        .from('user_profiles')
        .update(updateData)
        .eq('user_id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(
    String username, [
    String? excludeUserId,
  ]) async {
    try {
      var query = supabase
          .from('user_profiles')
          .select('user_id')
          .eq('username', username);

      if (excludeUserId != null) {
        query = query.neq('user_id', excludeUserId);
      }

      final response = await query;
      return response.isEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get user stats (profile with recipe count)
  Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final response = await supabase
          .from('user_stats')
          .select()
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  // Search users by username or full name (for future social features)
  Future<List<UserProfile>> searchUsers(String searchTerm) async {
    final response = await supabase
        .from('user_profiles')
        .select()
        .or('username.ilike.%$searchTerm%,full_name.ilike.%$searchTerm%')
        .limit(20);

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  // Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    await supabase.from('user_profiles').delete().eq('user_id', userId);
  }

  // Get or create user profile (helper method)
  Future<UserProfile> getOrCreateUserProfile({
    required String userId,
    required String email,
    String? fullName,
  }) async {
    // Try to get existing profile
    UserProfile? profile = await getUserProfile(userId);

    if (profile == null) {
      // Create new profile if doesn't exist
      profile = await createUserProfile(
        userId: userId,
        email: email,
        fullName: fullName,
      );
    }

    return profile;
  }

  // Update profile avatar (for future image upload feature)
  Future<String?> uploadAvatar(String userId, Uint8List fileBytes) async {
    try {
      await supabase.storage
          .from('avatars')
          .uploadBinary('$userId/avatar.jpg', fileBytes);

      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl('$userId/avatar.jpg');

      // Update profile with new avatar URL
      await updateUserProfile(userId: userId, avatarUrl: publicUrl);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Get dietary preferences options
  static List<String> getDietaryPreferencesOptions() {
    return [
      'vegetarian',
      'vegan',
      'halal',
      'kosher',
      'gluten-free',
      'dairy-free',
      'nut-free',
      'low-carb',
      'keto',
      'paleo',
    ];
  }

  // Get cooking level options
  static List<String> getCookingLevelOptions() {
    return ['beginner', 'intermediate', 'advanced'];
  }

  // Get popular cuisine types
  static List<String> getCuisineOptions() {
    return [
      'Indonesian',
      'Italian',
      'Chinese',
      'Japanese',
      'Thai',
      'Indian',
      'Mexican',
      'French',
      'American',
      'Mediterranean',
      'Korean',
      'Vietnamese',
    ];
  }
}
