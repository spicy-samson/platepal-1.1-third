import 'dart:convert'; // For json decoding
import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';
import 'package:platepal/components/RecipeCard.dart';
import 'package:platepal/components/AppBar.dart';
import 'package:platepal/pages/SearchByRecipePage.dart';

class StarredRecipesPage extends StatefulWidget {
  const StarredRecipesPage({super.key});

  @override
  _StarredRecipesPageState createState() => _StarredRecipesPageState();
}

class _StarredRecipesPageState extends State<StarredRecipesPage> {
  List<Map<String, dynamic>> _starredRecipes = [];
  List<Map<String, dynamic>> _fixedRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFixedRecipes();
    _loadStarredRecipes();
  }

  Future<void> _loadFixedRecipes() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/fixed-data/recipe.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _fixedRecipes = List<Map<String, dynamic>>.from(jsonData);
      });
    } catch (e) {
      debugPrint("Error loading fixed recipes: $e");
    }
  }

  Future<void> _loadStarredRecipes() async {
    setState(() {
      _isLoading = true;
    });
    final recipes = await DatabaseHelper.instance.queryStarredRecipes();
    if (mounted) {
      setState(() {
        _starredRecipes = recipes;
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getFixedData(String recipeName) {
    return _fixedRecipes.firstWhere(
      (recipe) => recipe['Recipe Name'] == recipeName,
      orElse: () => {},
    );
  }

  Future<void> _navigateToSearchRecipes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchByRecipePage()),
    );

    if (result == true || result == null) {
      await _loadStarredRecipes();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Favorite Recipes',
      ),
      body: RefreshIndicator(
        onRefresh: _loadStarredRecipes,
        child: _starredRecipes.isEmpty
            ? _buildEmptyState()
            : _buildRecipeList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No starred recipes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToSearchRecipes,
                    icon: const Icon(Icons.search),
                    label: const Text('Find Recipes to Star'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeList() {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _starredRecipes.length,
          itemBuilder: (context, index) {
            final recipe = _starredRecipes[index];
            final fixedData = _getFixedData(recipe['name']);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: RecipeCard(
                recipe: recipe,
                recipeId: recipe['id'],
                cookingTime: fixedData['Cooking Time'] ?? 'N/A',
                calories: fixedData['Nutritional Info']?['Calories'] ?? 'N/A',
                onStarToggle: _loadStarredRecipes,
              ),
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _navigateToSearchRecipes,
            tooltip: 'Add more recipes',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
