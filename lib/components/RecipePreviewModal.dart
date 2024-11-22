import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';

class RecipePreviewModal extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final String day;
  final String mealType;
  final Function(String, String, int, String) onAddToMealPlan;

  const RecipePreviewModal({
    super.key,
    required this.recipe,
    required this.day,
    required this.mealType,
    required this.onAddToMealPlan,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) {
        return Column(
          children: [
            AppBar(
              title: Text(recipe['name']),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/${recipe['img'] ?? 'default_recipe.jpg'}',
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['name'],
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          _buildRecipeInfo(),
                          const SizedBox(height: 16),
                          _buildIngredientsList(),
                          const SizedBox(height: 16),
                          _buildInstructions(),
                          const SizedBox(height: 16),
                          _buildNutritionalInfo(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  onAddToMealPlan(day, mealType, recipe['id'], recipe['name']);
                  Navigator.of(context).pop(); // Close the modal
                  Navigator.of(context).pop(); // Return to the main screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${recipe['name']} to $mealType on $day'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text('Add to $mealType on $day'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(Icons.restaurant_menu, recipe['difficulty'] ?? 'N/A'),
          _buildInfoItem(Icons.people, '${recipe['servings'] ?? 1} servings'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(text, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildIngredientsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.getRecipeIngredients(recipe['id']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No ingredients found.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingredients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...snapshot.data!.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('• ${ingredient['quantity']} ${ingredient['unit']} ${ingredient['name']}'),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildInstructions() {
    List<String> steps = (recipe['instructions'] as String).split('\n').where((step) => step.trim().isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Instructions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          int idx = entry.key;
          String step = entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${idx + 1}. ', style: const TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(step)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNutritionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nutritional Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildNutritionRow('Calories', recipe['calories'], 'kcal'),
        _buildNutritionRow('Protein', recipe['protein'], 'g'),
        _buildNutritionRow('Carbohydrates', recipe['carbohydrates'], 'g'),
        _buildNutritionRow('Fat', recipe['fat'], 'g'),
        _buildNutritionRow('Saturated Fat', recipe['saturated_fat'], 'g'),
        _buildNutritionRow('Cholesterol', recipe['cholesterol'], 'mg'),
        _buildNutritionRow('Sodium', recipe['sodium'], 'mg'),
      ],
    );
  }

  Widget _buildNutritionRow(String label, dynamic value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('$value $unit'),
        ],
      ),
    );
  }
}