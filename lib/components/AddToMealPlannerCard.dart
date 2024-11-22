import 'package:flutter/material.dart';
import 'package:platepal/database_helper.dart';

class AddToMealPlannerCard extends StatefulWidget {
  final int recipeId;
  final String recipeName;

  const AddToMealPlannerCard({
    super.key,
    required this.recipeId,
    required this.recipeName,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AddToMealPlannerCardState createState() => _AddToMealPlannerCardState();
}

class _AddToMealPlannerCardState extends State<AddToMealPlannerCard> {
  String? selectedDay;
  String? selectedMeal;
  final List<String> daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> mealsOfDay = ['Breakfast', 'Lunch', 'Dinner'];
  List<Map<String, dynamic>> existingMealPlanEntries = [];

  @override
  void initState() {
    super.initState();
    _loadExistingMealPlanEntries();
  }

  Future<void> _loadExistingMealPlanEntries() async {
    final entries = await DatabaseHelper.instance.getMealPlanEntriesForRecipe(widget.recipeId);
    setState(() {
      existingMealPlanEntries = entries;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meal Planner',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (existingMealPlanEntries.isNotEmpty) 
              _buildExistingEntriesInfo(),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Day of the Week'),
              value: selectedDay,
              items: daysOfWeek.map((String day) {
                return DropdownMenuItem<String>(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedDay = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Meal'),
              value: selectedMeal,
              items: mealsOfDay.map((String meal) {
                return DropdownMenuItem<String>(
                  value: meal,
                  child: Text(meal),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedMeal = newValue;
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: selectedDay != null && selectedMeal != null ? _addToMealPlanner : null,
              child: const Text('Add to Meal Planner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExistingEntriesInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This recipe is in your meal plan:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...existingMealPlanEntries.map((entry) => 
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${entry['day_of_week']} - ${entry['meal_of_day']}'),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => _showRemoveConfirmationDialog(context, entry),
                ),
              ],
            ),
          )
        ),
        const SizedBox(height: 8),
        const Text(
          'You can add it to additional days if you like.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  void _addToMealPlanner() async {
    try {
      await DatabaseHelper.instance.updateMealPlan(selectedDay!, selectedMeal!, widget.recipeId);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.recipeName} added to $selectedMeal on $selectedDay'),
          backgroundColor: Colors.green,
        ),
      );
      _loadExistingMealPlanEntries(); // Reload the existing entries
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding to meal planner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showRemoveConfirmationDialog(BuildContext context, Map<String, dynamic> entry) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove from Meal Planner'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to remove ${widget.recipeName} from ${entry['day_of_week']} - ${entry['meal_of_day']}?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remove'),
              onPressed: () {
                Navigator.of(context).pop();
                _removeFromMealPlanner(entry);
              },
            ),
          ],
        );
      },
    );
  }

  void _removeFromMealPlanner(Map<String, dynamic> entry) async {
    try {
      await DatabaseHelper.instance.removeMealPlanEntry(entry['id']);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.recipeName} removed from ${entry['day_of_week']} - ${entry['meal_of_day']}'),
          backgroundColor: Colors.orange,
        ),
      );
      _loadExistingMealPlanEntries(); // Reload the existing entries
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from meal planner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}