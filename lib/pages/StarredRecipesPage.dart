import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';
import 'package:platepal/components/RecipeCard.dart';
import 'package:platepal/components/AppBar.dart';
import 'package:platepal/pages/SearchByRecipePage.dart';

class StarredRecipesPage extends StatefulWidget {
  const StarredRecipesPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StarredRecipesPageState createState() => _StarredRecipesPageState();
}

class _StarredRecipesPageState extends State<StarredRecipesPage> {
  List<Map<String, dynamic>> _starredRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStarredRecipes();
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

  Future<void> _navigateToSearchRecipes() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchByRecipePage()),
    );
    
    // Refresh the list when returning from the search page
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
        title: 'Favorie Recipes',
      ),
      body: RefreshIndicator(
        onRefresh: _loadStarredRecipes,
        child: _starredRecipes.isEmpty
            ? LayoutBuilder(
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
              )
            : Stack(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _starredRecipes.length,
                    itemBuilder: (context, index) {
                      final recipe = _starredRecipes[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: RecipeCard(
                          recipe: recipe,
                          recipeId: recipe['id'],
                          onStarToggle: () {
                            // Refresh the list when a recipe is unstarred
                            _loadStarredRecipes();
                          },
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
              ),
      ),
    );
  }
}