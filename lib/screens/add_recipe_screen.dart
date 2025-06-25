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
      appBar: AppBar(title: const Text('Add Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorMessage.value != null)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  errorMessage.value!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Recipe Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: selectedImage.value != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          selectedImage.value!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Recipe Image',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Ingredients', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quantity field
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: ingredientQuantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      hintText: '1 cup, 250g, etc.',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                // Ingredient name field
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: ingredientNameController,
                    decoration: const InputDecoration(
                      labelText: 'Ingredient Name',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => addIngredient(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: addIngredient,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (ingredients.value.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: ingredients.value.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ingredient = Ingredient.fromString(
                      ingredients.value[index],
                    );
                    return ListTile(
                      leading: Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.secondaryColor,
                      ),
                      title: Text(
                        ingredient.name,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: ingredient.quantity.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.accentColor,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                ingredient.quantity,
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red.shade700,
                              ),
                              onPressed: () => removeIngredient(index),
                            ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            Row(
              children: [
                Icon(Icons.restaurant_rounded, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Cooking Steps',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: stepController,
                    decoration: const InputDecoration(
                      labelText: 'Add Step',
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (_) => addStep(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: addStep,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (steps.value.isNotEmpty) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: steps.value.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        steps.value[index],
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade700,
                        ),
                        onPressed: () => removeStep(index),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value ? null : saveRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: isLoading.value
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Recipe', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
