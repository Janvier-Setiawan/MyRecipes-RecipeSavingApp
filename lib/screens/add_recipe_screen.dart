import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/recipe.dart';
import '../providers/app_providers.dart';
import '../config/app_theme.dart';

class AddRecipeScreen extends HookConsumerWidget {
  const AddRecipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final ingredientNameController = useTextEditingController();
    final ingredientQuantityController = useTextEditingController();
    final stepController = useTextEditingController();
    final ingredients = useState<List<String>>([]);
    final steps = useState<List<String>>([]);
    final selectedImage = useState<File?>(null);
    final isLoading = useState(false);
    final errorMessage = useState<String?>(null);
    final pageController = usePageController();
    final currentPage = useState(0);

    final recipeService = ref.watch(recipeServiceProvider);
    final userId = ref.watch(currentUserProvider);

    void addIngredient() {
      final name = ingredientNameController.text.trim();
      final quantity = ingredientQuantityController.text.trim();

      if (name.isNotEmpty) {
        // Format: "quantity|name"
        final ingredient = Ingredient(name: name, quantity: quantity);
        ingredients.value = [...ingredients.value, ingredient.toString()];
        ingredientNameController.clear();
        ingredientQuantityController.clear();
      }
    }

    void removeIngredient(int index) {
      final newList = List<String>.from(ingredients.value);
      newList.removeAt(index);
      ingredients.value = newList;
    }

    void addStep() {
      if (stepController.text.isNotEmpty) {
        steps.value = [...steps.value, stepController.text];
        stepController.clear();
      }
    }

    void removeStep(int index) {
      final newList = List<String>.from(steps.value);
      newList.removeAt(index);
      steps.value = newList;
    }

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Limit image dimensions for better performance
        maxHeight: 1024,
        imageQuality: 85, // Slightly reduce quality for smaller file size
      );

      if (pickedFile != null) {
        selectedImage.value = File(pickedFile.path);
      }
    }

    void saveRecipe() async {
      // Validate inputs
      if (nameController.text.isEmpty || descriptionController.text.isEmpty) {
        errorMessage.value = 'Please fill in name and description';
        return;
      }

      if (ingredients.value.isEmpty) {
        errorMessage.value = 'Please add at least one ingredient';
        return;
      }

      if (userId == null) {
        errorMessage.value = 'You must be logged in to add a recipe';
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;

      try {
        await recipeService.addRecipe(
          userId: userId,
          name: nameController.text,
          description: descriptionController.text,
          ingredients: ingredients.value,
          steps: steps.value,
          imageFile: selectedImage.value,
        );

        // Refresh recipes
        ref.invalidate(userRecipesProvider(userId));

        if (context.mounted) {
          context.go('/home');
        }
      } catch (e) {
        errorMessage.value = 'Failed to save recipe: ${e.toString()}';
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Modern header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryColor, Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create New Recipe',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Share your culinary masterpiece with the world!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Error message
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

                    // Form container
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Recipe basic info
                          _buildSectionTitle(
                            'Recipe Details',
                            Icons.info_outline,
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Recipe Name',
                              hintText: 'Enter a delicious recipe name',
                              prefixIcon: Icon(Icons.restaurant_menu),
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                            ),
                          ),
                          const SizedBox(height: 20),

                          TextFormField(
                            controller: descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Tell us about this amazing recipe',
                              prefixIcon: Icon(Icons.description),
                              filled: true,
                              fillColor: AppTheme.surfaceColor,
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),

                          // Image picker
                          _buildSectionTitle(
                            'Recipe Photo',
                            Icons.photo_camera,
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: selectedImage.value != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          child: Image.file(
                                            selectedImage.value!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                        Positioned(
                                          top: 12,
                                          right: 12,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              onPressed: pickImage,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add_photo_alternate,
                                            size: 40,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Add Recipe Photo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Tap to select an image',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Ingredients section
                          _buildSectionTitle('Ingredients', Icons.list_alt),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: ingredientQuantityController,
                                  decoration: const InputDecoration(
                                    labelText: 'Quantity',
                                    hintText: '1 cup',
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                  ),
                                  onFieldSubmitted: (_) => addIngredient(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: ingredientNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Ingredient',
                                    hintText: 'Flour, Sugar, etc.',
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                  ),
                                  onFieldSubmitted: (_) => addIngredient(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: addIngredient,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (ingredients.value.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Added Ingredients (${ingredients.value.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: ingredients.value.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final ingredient = Ingredient.fromString(
                                        ingredients.value[index],
                                      );
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppTheme.secondaryColor
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: AppTheme.secondaryColor,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                ingredient.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            if (ingredient.quantity.isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.accentColor
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  ingredient.quantity,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme
                                                        .textPrimaryColor,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  removeIngredient(index),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Cooking steps section
                          _buildSectionTitle(
                            'Cooking Steps',
                            Icons.format_list_numbered,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: stepController,
                                  decoration: const InputDecoration(
                                    labelText: 'Add Step',
                                    hintText: 'Describe the cooking step',
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                  ),
                                  maxLines: 2,
                                  onFieldSubmitted: (_) => addStep(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: addStep,
                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          if (steps.value.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cooking Steps (${steps.value.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: steps.value.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.primaryColor
                                                .withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${index + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                steps.value[index],
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  removeStep(index),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Save button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading.value ? null : saveRecipe,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
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
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Recipe',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }
}
