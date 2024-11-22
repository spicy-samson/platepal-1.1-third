import 'package:flutter/material.dart';
import 'package:platepal/components/IngredientItem.dart';
import 'package:platepal/components/SelectedIngredientItem.dart';
import 'package:platepal/models/Ingredient.dart';
import 'package:platepal/database_helper.dart';
import 'package:platepal/pages/RecipePreviewPage.dart';
import 'package:platepal/components/AppBar.dart';

class SearchByIngredientsPage extends StatefulWidget {
  const SearchByIngredientsPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SearchByIngredientsPageState createState() => _SearchByIngredientsPageState();
}

class _SearchByIngredientsPageState extends State<SearchByIngredientsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<String> ingredientCategories = ['All'];
  List<Ingredient> selectedIngredients = [];
  Map<String, List<Ingredient>> categoryIngredients = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndIngredients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndIngredients() async {
    final categories = await DatabaseHelper.instance.queryAllIngredientCategories();
    final ingredients = await DatabaseHelper.instance.queryAllIngredients();
    
    setState(() {
      ingredientCategories = ['All', ...categories.map((c) => c['name'] as String)];
      _tabController = TabController(length: ingredientCategories.length, vsync: this);

      for (var category in ingredientCategories) {
        categoryIngredients[category] = ingredients
            .map((map) => Ingredient.fromMap(map))
            .where((ingredient) => category == 'All' || ingredient.category == category)
            .toList();
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Search by Ingredients',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: ingredientCategories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          _buildSelectedIngredients(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ingredientCategories.map((category) => _buildIngredientGrid(category)).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _searchRecipes,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text('Search Recipes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedIngredients() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's your Ingredients?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: selectedIngredients.isEmpty
                ? const Center(child: Text('Select ingredients to start'))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedIngredients.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            SelectedIngredientItem(
                              ingredient: selectedIngredients[index],
                              onRemove: () {
                                setState(() {
                                  selectedIngredients.removeAt(index);
                                });
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedIngredients[index].name,
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientGrid(String category) {
    List<Ingredient> ingredients = categoryIngredients[category] ?? [];

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        return IngredientItem(
          ingredient: ingredients[index],
          isSelected: selectedIngredients.contains(ingredients[index]),
          onTap: () {
            setState(() {
              if (selectedIngredients.contains(ingredients[index])) {
                selectedIngredients.remove(ingredients[index]);
              } else {
                selectedIngredients.add(ingredients[index]);
              }
            });
          },
        );
      },
    );
  }

  void _searchRecipes() async {
    if (selectedIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one ingredient')),
      );
      return;
    }

    List<int> selectedIngredientIds = selectedIngredients.map((i) => i.id).toList();
    final recipes = await DatabaseHelper.instance.searchRecipesByIngredients(selectedIngredientIds);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeListPage(recipes: recipes),
      ),
    );
  }
}

class RecipeListPage extends StatelessWidget {
  final List<Map<String, dynamic>> recipes;

  const RecipeListPage({super.key, required this.recipes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Matching Recipes'),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipePreviewPage(recipeId: recipe['id']),
                  ),
                );
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                    child: Image.asset(
                      'assets/images/${recipe['img'] ?? 'default_recipe.jpg'}',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe['name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Matched: ${recipe['matched_ingredients']} / ${recipe['total_ingredients']} ingredients',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Difficulty: ${recipe['difficulty'] ?? 'N/A'}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
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
        },
      ),
    );
  }
}