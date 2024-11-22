import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:platepal/pages/SearchByIngredientsPage.dart';
import 'package:platepal/pages/SearchByRecipePage.dart';
import 'package:platepal/pages/AccessMealPlannerPage.dart';
import 'package:platepal/pages/StarredRecipesPage.dart';
import 'package:platepal/components/AppBar.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showBackButton: false),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/platepal.svg',
                  height: 120,
                  width: 120,
                ),
                const SizedBox(height: 24),
                const Text(
                  'PlatePal',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildButton(
                          context,
                          'Search by Recipe',
                          Icons.search,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchByRecipePage()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          context,
                          'Search by Ingredients',
                          Icons.restaurant_menu,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const SearchByIngredientsPage()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          context,
                          'Access Meal Planner',
                          Icons.calendar_today,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const MealPlannerPage()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          context,
                          'Starred Recipes',
                          Icons.star,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StarredRecipesPage()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}