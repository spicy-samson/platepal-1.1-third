import 'package:flutter/material.dart';
import 'package:platepal/pages/home.dart';
import 'package:platepal/database_helper.dart';

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the database
  await DatabaseHelper.instance.database;
  
  // Optional: Insert sample data if needed
  // await insertSampleData();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

// Optional: Sample data insertion function
// Future<void> insertSampleData() async {
//   final dbHelper = DatabaseHelper.instance;
  
//   List<Map<String, dynamic>> recipes = [
//     {
//       'name': 'Chicken Adobo',
//       'instructions': 'Marinate chicken...',
//       'difficulty': 'easy',
//       'calories': 270,
//       'protein': 25,
//       'carbohydrates': 2,
//       'fat': 18,
//       'saturated_fat': 4,
//       'cholesterol': 80,
//       'sodium': 950,
//     },
//     // Add more recipes here...
//   ];

//   for (var recipe in recipes) {
//     await dbHelper.insertRecipe(recipe);
//   }
// }