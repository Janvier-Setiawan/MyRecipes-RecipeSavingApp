class Ingredient {
  final String name;
  final String quantity;

  Ingredient({required this.name, this.quantity = ''});

  @override
  String toString() {
    return "$quantity|$name";
  }

  static Ingredient fromString(String ingredientString) {
    final parts = ingredientString.split('|');
    if (parts.length == 2) {
      return Ingredient(name: parts[1], quantity: parts[0]);
    } else {
      return Ingredient(name: ingredientString);
    }
  }
}
