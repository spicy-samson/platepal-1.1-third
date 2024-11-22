import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platepal/database_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:platepal/components/AddToMealPlannerCard.dart';

class RecipePreviewPage extends StatefulWidget {
  final int recipeId;

  const RecipePreviewPage({super.key, required this.recipeId});

  @override
  _RecipePreviewPageState createState() => _RecipePreviewPageState();
}

class _RecipePreviewPageState extends State<RecipePreviewPage> {
  late Future<Map<String, dynamic>> _recipeFuture;
  late Future<List<Map<String, dynamic>>> _ingredientsFuture;
  late Future<Map<String, dynamic>> _fixedDataFuture;
  bool _isStarred = false;
  int _servings = 1;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipe();
    _ingredientsFuture = _loadIngredients();
    _fixedDataFuture = _loadFixedData();
  }

  Future<Map<String, dynamic>> _loadRecipe() async {
    final recipe = await DatabaseHelper.instance.getRecipe(widget.recipeId);
    setState(() {
      _isStarred = recipe['is_starred'] == 1;
      if (recipe['vid'] != null) {
        _initializeVideoPlayer(recipe['vid']);
      }
    });
    return recipe;
  }

  Future<List<Map<String, dynamic>>> _loadIngredients() async {
    return await DatabaseHelper.instance.getRecipeIngredients(widget.recipeId);
  }

  Future<Map<String, dynamic>> _loadFixedData() async {
    final String response =
        await rootBundle.loadString('assets/fixed-data/recipe.json');
    final List<dynamic> data = json.decode(response);
    return Map.fromEntries(
      data.map((item) {
        final name = item['Recipe Name'] ?? 'Unknown';
        final ingredients = item['Ingredients'] ?? [];
        final nutrition = item['Nutritional Info'] ?? {};

        return MapEntry(name, {
          'name': name,
          'Ingredients': ingredients,
          'Nutritional Info': nutrition,
        });
      }),
    );
  }

  Future<void> _toggleStarred() async {
    final newStarredValue = _isStarred ? 0 : 1;
    await DatabaseHelper.instance
        .updateRecipeStarred(widget.recipeId, newStarredValue);
    setState(() {
      _isStarred = !_isStarred;
    });
  }

  void _initializeVideoPlayer(String videoPath) async {
    _videoPlayerController =
        VideoPlayerController.asset('assets/videos/$videoPath');
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: false,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      placeholder: Container(
        color: Colors.grey,
      ),
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).primaryColor,
        handleColor: Theme.of(context).primaryColor,
        backgroundColor: Colors.grey,
        bufferedColor: Theme.of(context).primaryColorLight,
      ),
    );
    setState(() {});
  }

  // void _incrementServings() {
  //   setState(() {
  //     _servings++;
  //   });
  // }

  // void _decrementServings() {
  //   if (_servings > 1) {
  //     setState(() {
  //       _servings--;
  //     });
  //   }
  // }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _recipeFuture, // This is used to get data from the database
        builder: (context, recipeSnapshot) {
          if (recipeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (recipeSnapshot.hasError) {
            return Center(child: Text('Error: ${recipeSnapshot.error}'));
          } else if (!recipeSnapshot.hasData) {
            return const Center(child: Text('No recipe data found.'));
          }

          final recipe = recipeSnapshot.data!;

          // Load JSON data asynchronously using FutureBuilder
          return FutureBuilder<String>(
            future: rootBundle.loadString('assets/fixed-data/recipe.json'),
            builder: (context, jsonSnapshot) {
              if (jsonSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (jsonSnapshot.hasError) {
                return Center(
                    child: Text('Error loading JSON: ${jsonSnapshot.error}'));
              } else if (!jsonSnapshot.hasData) {
                return const Center(child: Text('No fixed recipe data found.'));
              }

              // Decode the JSON data
              final jsonData = json.decode(jsonSnapshot.data!);

              // Search for the recipe by matching the "Recipe Name"
              final fixedData = (jsonData as List).firstWhere(
                (r) => r['Recipe Name'] == recipe['name'],
                orElse: () => {}, // Return an empty map if not found
              );

              // Extract the Calories from the Nutritional Info
              final calories = fixedData.isNotEmpty &&
                      fixedData['Nutritional Info'] != null
                  ? fixedData['Nutritional Info']['Calories']
                  : 'Calories not available'; // Default message if Calories are not found

              final youtube_channel =
                  fixedData.isNotEmpty && fixedData['Youtube Channel'] != null
                      ? fixedData['Youtube Channel']
                      : 'Youtube channel not indicated';

              final resource_nutrition = fixedData.isNotEmpty &&
                      fixedData['Nutritional Information Source'] != null
                  ? fixedData['Nutritional Information Source']
                  : 'Not indicated';

              return CustomScrollView(
                slivers: [
                  _buildSliverAppBar(recipe),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildRecipeInfo(recipe, calories),
                          _buildServingAdjuster(),
                          const SizedBox(height: 16),
                          if (recipe['vid'] != null)
                            _buildVideoCard(youtube_channel),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            title: 'Ingredients',
                            content: _buildIngredientsList(
                                fixedData['Ingredients'] ?? []),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            title: 'Instructions',
                            content: _buildNumberedInstructions(
                                recipe['instructions']),
                          ),
                          const SizedBox(height: 16),
                          AddToMealPlannerCard(
                        recipeId: widget.recipeId,
                        recipeName: recipe['name'],
                      ),
                      const SizedBox(height: 16),
                          // _buildInfoCard(
                          //   title: 'Nutritional Information',
                          //   content: _buildNutritionalInfo(
                          //       fixedData['Nutritional Info'] ?? {}),
                          // ),
                          _buildNutritionColumn(
                            'Nutritional Information',
                            _buildNutritionalInfo(
                                fixedData['Nutritional Info'] ?? {}),
                              resource_nutrition,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> recipe) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          recipe['name'],
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/${recipe['img'] ?? 'default_recipe.jpg'}',
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isStarred ? Icons.star : Icons.star_border),
          onPressed: _toggleStarred,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildRecipeInfo(Map<String, dynamic> recipe, String calories) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildInfoColumn('Difficulty', recipe['difficulty']),
          _buildNutritionRow('Calories: ', calories, 'kcal'),
        ],
      ),
    );
  }

  Widget _buildServingAdjuster() {
    return const Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Servings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // IconButton(
                //   icon: const Icon(Icons.remove),
                //   onPressed: _decrementServings,
                // ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '4',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                // IconButton(
                //   icon: const Icon(Icons.add),
                //   onPressed: _incrementServings,
                // ),
              ],
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(String youtube_channel) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipe Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_chewieController != null)
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: Chewie(
                  controller: _chewieController!,
                ),
              )
            else
              const Center(child: CircularProgressIndicator()),
            const SizedBox(
              height: 16,
            ),
            Text(
              'Youtube channel: $youtube_channel',
              textAlign: TextAlign.center,
              // ignore: prefer_const_constructors
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionColumn(String label, Widget content, String resource) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            content,
            const SizedBox(height: 16,),

            Text(
              'Nutritional Resouce Information: $resource',
              textAlign: TextAlign.center,
              // ignore: prefer_const_constructors
              style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildIngredientsList(List<dynamic> ingredients) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ingredients.map((ingredient) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(ingredient)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInfoCard({required String title, required Widget content}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionalInfo(Map<String, dynamic> nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nutrition.entries.map((entry) {
        final value = entry.value?.toString() ?? 'N/A';
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(value),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNutritionRow(String label, String calories, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('$calories'),
        ],
      ),
    );
  }

  Widget _buildNumberedInstructions(String instructions) {
    List<String> steps = instructions
        .split('\n')
        .map((step) => step.trim().replaceAll('\n', ''))
        .where((step) => step.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: steps.asMap().entries.map((entry) {
        int idx = entry.key;
        String step = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${idx + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step,
                  style: const TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
