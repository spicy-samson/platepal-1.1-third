import 'package:flutter/material.dart';
import 'package:platepal/components/MealPlannerRecipeCard.dart';

class AddMealDialog extends StatefulWidget {
  final String day;
  final String mealType;
  final List<Map<String, dynamic>> recipes;
  final Function(String, String, int, String) onAddMeal;
  final Function(Map<String, dynamic>) onPreviewRecipe;

  const AddMealDialog({
    super.key,
    required this.day,
    required this.mealType,
    required this.recipes,
    required this.onAddMeal,
    required this.onPreviewRecipe,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AddMealDialogState createState() => _AddMealDialogState();
}

class _AddMealDialogState extends State<AddMealDialog> {
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = List.from(widget.recipes);
  }

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
              title: Text('Add ${widget.mealType} for ${widget.day}'),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search recipes...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (query) {
                  setState(() {
                    if (query.isEmpty) {
                      _searchResults = List.from(widget.recipes);
                    } else {
                      _searchResults = widget.recipes
                          .where((recipe) => recipe['name']
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                          .toList();
                    }
                  });
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: MealPlannerRecipeCard(
                      recipe: _searchResults[index],
                      onAdd: () {
                        widget.onAddMeal(
                          widget.day,
                          widget.mealType,
                          _searchResults[index]['id'],
                          _searchResults[index]['name'],
                        );
                        Navigator.of(context).pop();
                      },
                      onPreview: () => widget.onPreviewRecipe(_searchResults[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}