import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/recipe.dart';
import '../providers/app_providers.dart';
import '../config/app_theme.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeService = ref.watch(recipeServiceProvider);
    final userId = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'Delete Recipe',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  content: Text(
                    'Are you sure you want to delete this recipe?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  await recipeService.deleteRecipe(recipe.id);

                  // Refresh recipes
                  if (userId != null) {
                    ref.invalidate(userRecipesProvider(userId));
                  }

                  if (context.mounted) {
                    context.go('/home');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error deleting recipe: ${e.toString()}'),
                        backgroundColor: Colors.red.shade700,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.imageUrl != null)
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: CachedNetworkImage(
                  imageUrl: recipe.imageUrl!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 250,
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              recipe.name,
              style: Theme.of(
                context,
              ).textTheme.displayMedium?.copyWith(color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Added on ${DateFormat('MMMM d, yyyy').format(recipe.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.description_rounded, color: AppTheme.secondaryColor),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recipe.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  color: AppTheme.secondaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ingredients',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: recipe.ingredients.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ingredient = Ingredient.fromString(
                    recipe.ingredients[index],
                  );
                  return ListTile(
                    leading: Icon(
                      Icons.check_circle_rounded,
                      color: AppTheme.primaryColor,
                    ),
                    title: Text(ingredient.name),
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
                        : null,
                  );
                },
              ),
            ),

            // Display cooking steps if there are any
            if (recipe.steps.isNotEmpty) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(
                    Icons.restaurant_rounded,
                    color: AppTheme.secondaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cooking Steps',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: recipe.steps.length,
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
                      title: Text(recipe.steps[index]),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
