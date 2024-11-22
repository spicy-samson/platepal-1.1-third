import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';
import 'package:platepal/components/AppBar.dart';
import 'package:platepal/components/DayCard.dart';
import 'package:platepal/components/AddMealDialog.dart';
import 'package:platepal/components/RecipePreviewModal.dart';

class MealPlannerPage extends StatefulWidget {
  const MealPlannerPage({super.key});

  @override
  State<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends State<MealPlannerPage> {
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> mealTypes = ['Breakfast', 'Lunch', 'Dinner'];
  late List<String> orderedDays;
  late String currentDay;
  late String currentMealType;
  final Map<String, Map<String, String>> mealPlan = {
    'Monday': {}, 'Tuesday': {}, 'Wednesday': {}, 'Thursday': {}, 'Friday': {}, 'Saturday': {}, 'Sunday': {},
  };
  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    _initializeCurrentDayAndMeal();
    _loadRecipes();
    _loadMealPlan();
  }

  void _initializeCurrentDayAndMeal() {
    final now = DateTime.now();
    currentDay = days[now.weekday - 1];
    currentMealType = now.hour < 11 ? 'Breakfast' : (now.hour < 16 ? 'Lunch' : 'Dinner');
    int currentIndex = days.indexOf(currentDay);
    orderedDays = [...days.sublist(currentIndex), ...days.sublist(0, currentIndex)];
  }

  Future<void> _loadRecipes() async {
    final loadedRecipes = await DatabaseHelper.instance.queryAllRecipes();
    if (mounted) {
      setState(() {
        recipes = loadedRecipes;
      });
    }
  }

  Future<void> _loadMealPlan() async {
    final loadedMealPlan = await DatabaseHelper.instance.getMealPlan();
    if (mounted) {
      setState(() {
        for (var meal in loadedMealPlan) {
          mealPlan[meal['day_of_week']]?[meal['meal_of_day']] = meal['recipe_name'];
        }
      });
    }
  }

  Future<void> _updateMealPlan(String day, String mealType, int recipeId, String recipeName) async {
    await DatabaseHelper.instance.updateMealPlan(day, mealType, recipeId);
    setState(() {
      mealPlan[day]?[mealType] = recipeName;
    });
  }

  void _showAddMealDialog(BuildContext context, String day, String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return AddMealDialog(
          day: day,
          mealType: mealType,
          recipes: recipes,
          onAddMeal: _updateMealPlan,
          onPreviewRecipe: (recipe) => _showRecipePreview(recipe, day, mealType),
        );
      },
    );
  }

  void _showRecipePreview(Map<String, dynamic> recipe, String day, String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return RecipePreviewModal(
          recipe: recipe,
          day: day,
          mealType: mealType,
          onAddToMealPlan: _updateMealPlan,
        );
      },
    );
  }

  Map<String, int> _getMealRecipeIds(String day) {
    Map<String, int> recipeIds = {};
    for (String mealType in mealTypes) {
      String? recipeName = mealPlan[day]?[mealType];
      if (recipeName != null) {
        int recipeId = recipes.firstWhere((r) => r['name'] == recipeName)['id'];
        recipeIds[mealType] = recipeId;
      }
    }
    return recipeIds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Meal Planner'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today is $currentDay',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final day = orderedDays[index];
                    return DayCard(
                      day: day,
                      isCurrentDay: day == currentDay,
                      mealPlan: mealPlan[day] ?? {},
                      mealRecipeIds: _getMealRecipeIds(day),
                      mealTypes: mealTypes,
                      currentMealType: currentMealType,
                      onAddMeal: (mealType) => _showAddMealDialog(context, day, mealType),
                      onPreviewRecipe: (recipeName, mealType) {
                        final recipe = recipes.firstWhere((r) => r['name'] == recipeName);
                        _showRecipePreview(recipe, day, mealType);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}