import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';
import 'package:platepal/components/RecipeCard.dart';
import 'package:platepal/components/AppBar.dart';

class SearchByRecipePage extends StatefulWidget {
  const SearchByRecipePage({super.key});

  @override
  _SearchByRecipePageState createState() => _SearchByRecipePageState();
}

class _SearchByRecipePageState extends State<SearchByRecipePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _searchResults = [];
  TabController? _tabController;
  List<String> _categories = ['All'];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndRecipes();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoriesAndRecipes() async {
    final categories = await DatabaseHelper.instance.queryAllRecipeCategories();
    final recipes = await DatabaseHelper.instance.queryAllRecipes();
    
    if (mounted) {
      setState(() {
        _categories = ['All', ...categories.map((c) => c['name'] as String)];
        _recipes = recipes;
        _tabController = TabController(length: _categories.length, vsync: this);
        _isLoading = false;
      });
    }
  }

  void _searchRecipes(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
    } else {
      final results = await DatabaseHelper.instance.searchRecipes(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredRecipes(String category) {
    if (category == 'All') {
      return _recipes;
    } else {
      return _recipes.where((recipe) => recipe['category_name'] == category).toList();
    }
  }

  Future<void> _refreshRecipes() async {
    final updatedRecipes = await DatabaseHelper.instance.queryAllRecipes();
    if (mounted) {
      setState(() {
        _recipes = updatedRecipes;
      });
    }
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (_, controller) {
                return Column(
                  children: [
                    CustomAppBar(
                      title: 'Search Recipes',
                      showBackButton: false,
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
                        controller: _searchController,
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
                          _searchRecipes(query);
                          setModalState(() {});
                        },
                      ),
                    ),
                    Expanded(
                      child: _searchResults.isEmpty
                          ? const Center(child: Text('No results found'))
                          : ListView.builder(
                              controller: controller,
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  child: RecipeCard(
                                    recipe: _searchResults[index],
                                    recipeId: _searchResults[index]['id'],
                                    onStarToggle: () {
                                      _refreshRecipes();
                                      setModalState(() {});
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'What to cook?',
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _getFilteredRecipes(category).length,
                  itemBuilder: (context, index) {
                    final recipe = _getFilteredRecipes(category)[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: RecipeCard(
                        recipe: recipe,
                        recipeId: recipe['id'],
                        onStarToggle: () {
                          _refreshRecipes();
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showSearchModal(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text('Search'),
            ),
          ),
        ],
      ),
    );
  }
}