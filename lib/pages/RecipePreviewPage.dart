import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:platepal/components/AddToMealPlannerCard.dart';

class RecipePreviewPage extends StatefulWidget {
  final int recipeId;

  const RecipePreviewPage({super.key, required this.recipeId});

  @override
  // ignore: library_private_types_in_public_api
  _RecipePreviewPageState createState() => _RecipePreviewPageState();
}

class _RecipePreviewPageState extends State<RecipePreviewPage> {
  late Future<Map<String, dynamic>> _recipeFuture;
  late Future<List<Map<String, dynamic>>> _ingredientsFuture;
  bool _isStarred = false;
  int _servings = 1;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _recipeFuture = _loadRecipe();
    _ingredientsFuture = _loadIngredients();
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

  void _initializeVideoPlayer(String videoPath) async {
    _videoPlayerController = VideoPlayerController.asset('assets/videos/$videoPath');
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
        // ignore: use_build_context_synchronously
        playedColor: Theme.of(context).primaryColor,
        // ignore: use_build_context_synchronously
        handleColor: Theme.of(context).primaryColor,
        backgroundColor: Colors.grey,
        // ignore: use_build_context_synchronously
        bufferedColor: Theme.of(context).primaryColorLight,
      ),
    );
    setState(() {});
  }

  Future<void> _toggleStarred() async {
    final newStarredValue = _isStarred ? 0 : 1;
    await DatabaseHelper.instance.updateRecipeStarred(widget.recipeId, newStarredValue);
    setState(() {
      _isStarred = !_isStarred;
    });
  }

  void _incrementServings() {
    setState(() {
      _servings++;
    });
  }

  void _decrementServings() {
    if (_servings > 1) {
      setState(() {
        _servings--;
      });
    }
  }

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
        future: _recipeFuture,
        builder: (context, recipeSnapshot) {
          if (recipeSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (recipeSnapshot.hasError) {
            return Center(child: Text('Error: ${recipeSnapshot.error}'));
          } else if (!recipeSnapshot.hasData) {
            return const Center(child: Text('No recipe data found.'));
          }

          final recipe = recipeSnapshot.data!;
          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(recipe),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRecipeInfo(recipe),
                      _buildServingAdjuster(),
                      const SizedBox(height: 16),
                      if (recipe['vid'] != null) _buildVideoCard(),
                      const SizedBox(height: 16),
                      _buildIngredientsCard(),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Instructions',
                        content: _buildNumberedInstructions(recipe['instructions']),
                      ),
                      const SizedBox(height: 16),
                      AddToMealPlannerCard(
                        recipeId: widget.recipeId,
                        recipeName: recipe['name'],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        title: 'Nutritional Information',
                        content: _buildNutritionalInfo(recipe),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildRecipeInfo(Map<String, dynamic> recipe) {
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
          _buildNutritionRow('Calories: ', recipe['calories'], 'kcal'),
        ],
      ),
    );
  }

  Widget _buildServingAdjuster() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Servings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _decrementServings,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_servings',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _incrementServings,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Ingredient quantities are automatically adjusted. For large batch cooking, please refer to additional sources to ensure accuracy.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard() {
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

  Widget _buildIngredientsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _ingredientsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No ingredients found.'));
        }

        final ingredients = snapshot.data!;
        return _buildInfoCard(
          title: 'Ingredients',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: ingredients.map((ingredient) {
              num adjustedQuantity = (ingredient['quantity'] as num) * _servings;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text('${adjustedQuantity.toStringAsFixed(1)} ${ingredient['unit']} ${ingredient['name']}'),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
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

  Widget _buildNutritionalInfo(Map<String, dynamic> recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            _buildNutritionRow('Calories', recipe['calories'], 'kcal'),
            _buildNutritionRow('Protein', recipe['protein'], 'g'),
            _buildNutritionRow('Carbohydrates', recipe['carbohydrates'], 'g'),
            _buildNutritionRow('Fat', recipe['fat'], 'g'),
            _buildNutritionRow('Saturated Fat', recipe['saturated_fat'], 'g'),
            _buildNutritionRow('Cholesterol', recipe['cholesterol'], 'mg'),
            _buildNutritionRow('Sodium', recipe['sodium'], 'mg'),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Note: Nutritional values are estimates and may vary. Values shown are for the entire recipe.',
          style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, dynamic value, String unit) {
    num scaledValue = (value as num) * _servings;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('${scaledValue.toStringAsFixed(1)} $unit'),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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