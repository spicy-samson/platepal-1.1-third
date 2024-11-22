import 'package:flutter/material.dart';
import 'package:platepal/pages/RecipePreviewPage.dart';
import 'package:platepal/database_helper.dart';

class RecipeCard extends StatefulWidget {
  final Map<String, dynamic> recipe;
  final int recipeId;
  final VoidCallback? onStarToggle;
  final double imageHeight = 200.0; // Fixed height for the image

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.recipeId,
    this.onStarToggle,
  });

  @override
  // ignore: library_private_types_in_public_api
  _RecipeCardState createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard> {
  late bool isStarred;

  @override
  void initState() {
    super.initState();
    isStarred = widget.recipe['is_starred'] == 1;
  }

  void _toggleStar() async {
    final newStarredValue = isStarred ? 0 : 1;
    await DatabaseHelper.instance.updateRecipeStarred(widget.recipeId, newStarredValue);
    setState(() {
      isStarred = !isStarred;
    });
    widget.onStarToggle?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipePreviewPage(recipeId: widget.recipeId),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.asset(
                    'assets/images/${widget.recipe['img'] ?? 'default_recipe.jpg'}',
                    height: widget.imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: widget.imageHeight,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        ),
                      );
                    },
                  ),
                ),
                GestureDetector(
                  onTap: _toggleStar,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      isStarred ? Icons.star : Icons.star_border,
                      color: isStarred ? Colors.amber : Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.recipe['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Difficulty: ${widget.recipe['difficulty'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Calories: ${widget.recipe['calories'] ?? 'N/A'} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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