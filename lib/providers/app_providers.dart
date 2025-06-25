import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/auth_service.dart';
import '../services/recipe_service.dart';
import '../services/user_profile_service.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StateProvider<String?>((ref) => null);

// Recipe service provider
final recipeServiceProvider = Provider<RecipeService>((ref) {
  return RecipeService();
});

// User profile service provider
final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

// User recipes provider
final userRecipesProvider = FutureProvider.family<List<Recipe>, String>((
  ref,
  userId,
) async {
  final recipeService = ref.watch(recipeServiceProvider);
  return await recipeService.getUserRecipes(userId);
});

// User profile provider
final userProfileProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return await userProfileService.getUserProfile(userId);
});

// Current user profile provider (for the logged-in user)
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserProvider);
  if (userId == null) return null;

  final userProfileService = ref.watch(userProfileServiceProvider);
  return await userProfileService.getUserProfile(userId);
});

// User stats provider
final userStatsProvider = FutureProvider.family<Map<String, dynamic>?, String>((
  ref,
  userId,
) async {
  final userProfileService = ref.watch(userProfileServiceProvider);
  return await userProfileService.getUserStats(userId);
});

// Is first launch provider
final isFirstLaunchProvider = StateProvider<bool>((ref) => true);
