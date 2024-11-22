import 'package:flutter/material.dart';

class MealPlannerRecipePreview extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback onAdd;

  const MealPlannerRecipePreview({
    Key? key,
    required this.recipe,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.asset(
                'assets/images/${recipe['img'] ?? 'default_recipe.jpg'}',
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Difficulty: ${recipe['difficulty']}'),
                  Text('Calories: ${recipe['calories']} kcal'),
                  const SizedBox(height: 16),
                  const Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((recipe['ingredients'] as List<String>?)?.map((ingredient) => Text('• $ingredient')) ?? []),
                  const SizedBox(height: 16),
                  const Text('Instructions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(recipe['instructions'] ?? 'No instructions available.'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      onAdd();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('Add to Meal Plan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}