import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../models/recipe.dart';

class RecipeService {
  final supabase = SupabaseConfig.supabase;
  final String _bucketName = 'recipe_images';

  // Get all recipes for a user
  Future<List<Recipe>> getUserRecipes(String userId) async {
    final response = await supabase
        .from('recipes')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((json) => Recipe.fromJson(json)).toList();
  }

  // Upload an image to storage and get the public URL
  Future<String?> uploadImage(File imageFile, String userId) async {
    try {
      final fileExt = path.extension(imageFile.path);
      final fileName = '${const Uuid().v4()}$fileExt';
      final filePath = '$userId/$fileName';

      // Check if bucket exists, create if it doesn't
      final buckets = await supabase.storage.listBuckets();
      if (!buckets.any((bucket) => bucket.name == _bucketName)) {
        await supabase.storage.createBucket(
          _bucketName,
          const BucketOptions(
            public:
                true, // Make bucket public so we can access images without authentication
            fileSizeLimit: '5242880', // 5MB limit as string
          ),
        );
      }

      // Upload the file
      await supabase.storage
          .from(_bucketName)
          .upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get the public URL
      final imageUrl = supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  // Add a new recipe
  Future<Recipe> addRecipe({
    required String userId,
    required String name,
    required String description,
    required List<String> ingredients,
    List<String>? steps,
    File? imageFile,
  }) async {
    String? imageUrl;

    // Upload image if provided
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile, userId);
    }

    final newRecipeData = {
      'user_id': userId,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps ?? [], // Include steps, default to empty list
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    final response = await supabase
        .from('recipes')
        .insert(newRecipeData)
        .select();

    return Recipe.fromJson(response[0]);
  }

  // Delete a recipe
  Future<void> deleteRecipe(String recipeId) async {
    await supabase.from('recipes').delete().eq('id', recipeId);
  }

  // Update a recipe
  Future<Recipe> updateRecipe({
    required String recipeId,
    required String name,
    required String description,
    required List<String> ingredients,
    List<String>? steps,
    File? imageFile,
    String? userId,
  }) async {
    // Start with the basic update data
    final updatedData = {
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
    };

    // If there's a new image file and we have a userId (needed for path structure)
    if (imageFile != null && userId != null) {
      final imageUrl = await uploadImage(imageFile, userId);
      if (imageUrl != null) {
        updatedData['image_url'] = imageUrl;
      }
    }

    final response = await supabase
        .from('recipes')
        .update(updatedData)
        .eq('id', recipeId)
        .select();

    return Recipe.fromJson(response[0]);
  }
}
