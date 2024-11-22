import 'package:flutter/material.dart';
import 'package:platepal/pages/RecipePreviewPage.dart';

class DayCard extends StatelessWidget {
  final String day;
  final bool isCurrentDay;
  final Map<String, String> mealPlan;
  final Map<String, int> mealRecipeIds;
  final List<String> mealTypes;
  final String currentMealType;
  final Function(String) onAddMeal;
  final Function(String, String) onPreviewRecipe;

  const DayCard({
    super.key,
    required this.day,
    required this.isCurrentDay,
    required this.mealPlan,
    required this.mealRecipeIds,
    required this.mealTypes,
    required this.currentMealType,
    required this.onAddMeal,
    required this.onPreviewRecipe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: isCurrentDay ? const Color(0xFFE2E8F0) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isCurrentDay,
          title: Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isCurrentDay ? const Color(0xFF2563EB) : const Color(0xFF334155),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: mealTypes.map((mealType) => _buildMealSection(mealType, context)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealType, BuildContext context) {
    bool isCurrentMeal = isCurrentDay && mealType == currentMealType;
    int? recipeId = mealRecipeIds[mealType];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCurrentMeal ? const Color(0xFF2563EB) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: isCurrentMeal ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mealPlan[mealType] ?? 'Add a meal',
                    style: TextStyle(
                      fontSize: 14,
                      color: mealPlan[mealType] != null ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                if (mealPlan[mealType] != null && recipeId != null)
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipePreviewPage(recipeId: recipeId),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.add, color: Color(0xFF64748B)),
                  onPressed: () => onAddMeal(mealType),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}