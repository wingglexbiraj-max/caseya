/// Service and template architecture for standard product recipes & ingredients
///
/// Designed to support:
/// - Initial products (Lassi, Curd, Milk Pouch)
/// - Extensible catalog of additional plant products
/// - Auto-population of ingredient rows based on product formulation
/// - Future recipe scaling & automated calculations
class StandardRecipeIngredient {
  final String ingredientName;
  final String unit;
  final double defaultRatio; // per 100 units of product

  const StandardRecipeIngredient({
    required this.ingredientName,
    required this.unit,
    this.defaultRatio = 0.0,
  });
}

class StandardRecipe {
  final String productName;
  final String category;
  final String defaultUnit;
  final List<StandardRecipeIngredient> ingredients;

  const StandardRecipe({
    required this.productName,
    required this.category,
    required this.defaultUnit,
    required this.ingredients,
  });
}

class BatchRecipeService {
  /// Common dairy ingredients for quick dropdown / autocomplete suggestions
  static const List<String> commonIngredients = [
    'Milk',
    'Water',
    'SMP (Skimmed Milk Powder)',
    'Sugar',
    'Curd Culture',
    'Cream',
    'Citric Acid',
    'Lassi Flavour / Essence',
    'Stabilizer',
  ];

  /// Standard batch units
  static const List<String> batchUnits = ['L', 'kg', 'pieces', 'crates'];

  /// Ingredient units
  static const List<String> ingredientUnits = ['L', 'kg', 'g', 'ml', 'bags'];

  /// Standard product formulation templates
  static const List<StandardRecipe> standardRecipes = [
    StandardRecipe(
      productName: 'Lassi',
      category: 'Fermented',
      defaultUnit: 'L',
      ingredients: [
        StandardRecipeIngredient(ingredientName: 'Milk', unit: 'L', defaultRatio: 60.0), // 300L per 500L
        StandardRecipeIngredient(ingredientName: 'Water', unit: 'L', defaultRatio: 40.0), // 200L per 500L
        StandardRecipeIngredient(ingredientName: 'SMP', unit: 'kg', defaultRatio: 5.8),   // 29kg per 500L
        StandardRecipeIngredient(ingredientName: 'Sugar', unit: 'kg', defaultRatio: 9.2), // 46kg per 500L
      ],
    ),
    StandardRecipe(
      productName: 'Curd',
      category: 'Curd',
      defaultUnit: 'L',
      ingredients: [
        StandardRecipeIngredient(ingredientName: 'Milk', unit: 'L', defaultRatio: 100.0),
        StandardRecipeIngredient(ingredientName: 'Curd Culture', unit: 'g', defaultRatio: 0.1),
      ],
    ),
    StandardRecipe(
      productName: 'Milk Pouch',
      category: 'Milk',
      defaultUnit: 'L',
      ingredients: [
        StandardRecipeIngredient(ingredientName: 'Milk', unit: 'L', defaultRatio: 100.0),
      ],
    ),
    StandardRecipe(
      productName: 'Sweet Curd',
      category: 'Curd',
      defaultUnit: 'kg',
      ingredients: [
        StandardRecipeIngredient(ingredientName: 'Milk', unit: 'L', defaultRatio: 90.0),
        StandardRecipeIngredient(ingredientName: 'Sugar', unit: 'kg', defaultRatio: 8.0),
        StandardRecipeIngredient(ingredientName: 'SMP', unit: 'kg', defaultRatio: 2.0),
        StandardRecipeIngredient(ingredientName: 'Curd Culture', unit: 'g', defaultRatio: 0.1),
      ],
    ),
    StandardRecipe(
      productName: 'Paneer',
      category: 'Cheese',
      defaultUnit: 'kg',
      ingredients: [
        StandardRecipeIngredient(ingredientName: 'Milk', unit: 'L', defaultRatio: 500.0), // ~500L milk per 100kg paneer
        StandardRecipeIngredient(ingredientName: 'Citric Acid', unit: 'kg', defaultRatio: 0.8),
      ],
    ),
  ];

  static StandardRecipe? getRecipeForProduct(String productName) {
    try {
      return standardRecipes.firstWhere(
        (r) => r.productName.toLowerCase() == productName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// List of initial supported products
  static List<String> getSupportedProducts() {
    return [
      'Lassi',
      'Curd',
      'Milk Pouch',
      'Sweet Curd',
      'Paneer',
    ];
  }
}
