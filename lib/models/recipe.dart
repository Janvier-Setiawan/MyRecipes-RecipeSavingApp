class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, required this.quantity});

  factory Ingredient.fromString(String input) {
    // Format is expected to be "quantity|name"
    final parts = input.split('|');
    if (parts.length == 2) {
      return Ingredient(quantity: parts[0], name: parts[1]);
    }
    // Fallback for old data format or invalid format
    return Ingredient(quantity: '', name: input);
  }

  String toString() {
    return '$quantity|$name';
  }
}

class Recipe {
  final String id;
  final String userId;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String? imageUrl;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.createdAt,
    this.steps = const [], // Default to empty list if not provided
    this.imageUrl,
  });

  List<Ingredient> get parsedIngredients {
    return ingredients.map((item) => Ingredient.fromString(item)).toList();
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ingredients: List<String>.from(json['ingredients']),
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
