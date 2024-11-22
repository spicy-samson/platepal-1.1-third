import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'dart:typed_data';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'recipes.db');
      print("Target database path: $path");

      var exists = await databaseExists(path);
      print("Database exists: $exists");

      if (!exists) {
        print("Attempting to copy database from assets");

        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (e) {
          print("Error creating directory: $e");
        }

        ByteData data;
        try {
          List<String> possiblePaths = [
            "assets/platepal.db",
            "assets/db/platepal.db",
            "assets/database/platepal.db",
          ];

          data = await _loadAsset(possiblePaths);
          print("Asset loaded, size: ${data.lengthInBytes} bytes");
        } catch (e) {
          print("Error loading asset: $e");
          rethrow;
        }

        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

        try {
          await File(path).writeAsBytes(bytes, flush: true);
          print("Database copied to documents directory");
        } catch (e) {
          print("Error writing database file: $e");
          rethrow;
        }
      } else {
        print("Opening existing database");
      }

      return await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          print(
              "onCreate called. This should not happen with a pre-populated database.");
        },
        onOpen: (Database db) async {
          print("Database opened successfully.");
          var tables = await db.query('sqlite_master', columns: ['name']);
          print(
              "Tables in the database: ${tables.map((e) => e['name']).toList()}");
        },
      );
    } catch (e) {
      print("Error in _initDatabase: $e");
      rethrow;
    }
  }

  Future<ByteData> _loadAsset(List<String> paths) async {
    for (String path in paths) {
      try {
        return await rootBundle.load(path);
      } catch (e) {
        print("Failed to load asset from: $path");
      }
    }
    throw Exception(
        "Could not find the database asset in any of the expected locations");
  }

  Future<List<Map<String, dynamic>>> queryAllRecipes() async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT recipes.*, recipe_categories.name as category_name
        FROM recipes
        JOIN recipe_categories ON recipes.category_id = recipe_categories.id
      ''');
      print("Queried ${result.length} recipes");
      return result;
    } catch (e) {
      print("Error querying recipes: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecipe(int id) async {
    try {
      Database db = await instance.database;
      var results = await db.rawQuery('''
        SELECT recipes.*, recipe_categories.name as category_name
        FROM recipes
        JOIN recipe_categories ON recipes.category_id = recipe_categories.id
        WHERE recipes.id = ?
      ''', [id]);
      print("Queried recipe with id $id. Found: ${results.isNotEmpty}");
      if (results.isNotEmpty) {
        return results.first;
      } else {
        throw Exception('Recipe not found');
      }
    } catch (e) {
      print("Error getting recipe by id: $e");
      rethrow;
    }
  }

  Future<bool> mealPlanEntryExists(
      String day, String meal, int recipeId) async {
    final db = await database;
    final result = await db.query(
      'meal_plan',
      where: 'day_of_week = ? AND meal_of_day = ? AND recipe_id = ?',
      whereArgs: [day, meal, recipeId],
    );
    return result.isNotEmpty;
  }

  Future<int> updateMealPlan(String day, String meal, int recipeId) async {
    final db = await database;

    // Check if entry already exists
    bool exists = await mealPlanEntryExists(day, meal, recipeId);
    if (exists) {
      // Entry already exists, return -1 to indicate no change
      return -1;
    }

    // Entry doesn't exist, insert new entry
    return await db.insert('meal_plan',
        {'day_of_week': day, 'meal_of_day': meal, 'recipe_id': recipeId},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMealPlan() async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT meal_plan.*, recipes.name as recipe_name
        FROM meal_plan
        JOIN recipes ON meal_plan.recipe_id = recipes.id
      ''');
      print("Retrieved ${result.length} meal plan entries");
      return result;
    } catch (e) {
      print("Error getting meal plan: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getRecipeIngredients(int recipeId) async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT ingredients.*, recipe_ingredients.quantity, recipe_ingredients.unit
        FROM ingredients
        JOIN recipe_ingredients ON ingredients.id = recipe_ingredients.ingredient_id
        WHERE recipe_ingredients.recipe_id = ?
      ''', [recipeId]);
      print("Retrieved ${result.length} ingredients for recipe $recipeId");
      return result;
    } catch (e) {
      print("Error retrieving ingredients for recipe: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllRecipeCategories() async {
    try {
      Database db = await instance.database;
      var result = await db.query('recipe_categories');
      print("Queried ${result.length} recipe categories");
      return result;
    } catch (e) {
      print("Error querying recipe categories: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllIngredientCategories() async {
    try {
      Database db = await instance.database;
      var result = await db.query('ingredient_categories', orderBy: 'id');
      print("Queried ${result.length} ingredient categories");
      return result;
    } catch (e) {
      print("Error querying ingredient categories: $e");
      rethrow;
    }
  }

  Future<int> insertRecipe(Map<String, dynamic> row) async {
    try {
      Database db = await instance.database;
      var result = await db.insert('recipes', row);
      print("Inserted recipe with id: $result");
      return result;
    } catch (e) {
      print("Error inserting recipe: $e");
      rethrow;
    }
  }

  Future<int> updateRecipe(Map<String, dynamic> row) async {
    try {
      Database db = await instance.database;
      int id = row['id'];
      var result =
          await db.update('recipes', row, where: 'id = ?', whereArgs: [id]);
      print("Updated recipe with id: $id");
      return result;
    } catch (e) {
      print("Error updating recipe: $e");
      rethrow;
    }
  }

  Future<int> deleteRecipe(int id) async {
    try {
      Database db = await instance.database;
      var result = await db.delete('recipes', where: 'id = ?', whereArgs: [id]);
      print("Deleted recipe with id: $id");
      return result;
    } catch (e) {
      print("Error deleting recipe: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT recipes.*, recipe_categories.name as category_name
        FROM recipes
        JOIN recipe_categories ON recipes.category_id = recipe_categories.id
        WHERE recipes.name LIKE ?
      ''', ['%$query%']);
      print("Found ${result.length} recipes matching query: $query");
      return result;
    } catch (e) {
      print("Error searching recipes: $e");
      rethrow;
    }
  }

  Future<void> updateRecipeStarred(int id, int isStarred) async {
    try {
      Database db = await instance.database;
      await db.update(
        'recipes',
        {'is_starred': isStarred},
        where: 'id = ?',
        whereArgs: [id],
      );
      print("Updated starred status for recipe with id: $id to $isStarred");
    } catch (e) {
      print("Error updating recipe starred status: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryAllIngredients() async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT ingredients.*, ingredient_categories.name as category_name
        FROM ingredients
        JOIN ingredient_categories ON ingredients.category_id = ingredient_categories.id
        ORDER BY ingredient_categories.id, ingredients.name
      ''');
      print("Queried ${result.length} ingredients");
      return result;
    } catch (e) {
      print("Error querying ingredients: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryIngredientsByCategory(
      String category) async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
        SELECT ingredients.*, ingredient_categories.name as category_name
        FROM ingredients
        JOIN ingredient_categories ON ingredients.category_id = ingredient_categories.id
        WHERE ingredient_categories.name = ?
      ''', [category]);
      print("Queried ${result.length} ingredients for category: $category");
      return result;
    } catch (e) {
      print("Error querying ingredients by category: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchRecipesByIngredients(
      List<int> ingredientIds) async {
    try {
      Database db = await instance.database;
      String placeholders = List.filled(ingredientIds.length, '?').join(',');
      var result = await db.rawQuery('''
        SELECT recipes.*, recipe_categories.name as category_name,
               COUNT(DISTINCT recipe_ingredients.ingredient_id) as matched_ingredients,
               (SELECT COUNT(*) FROM recipe_ingredients WHERE recipe_id = recipes.id) as total_ingredients
        FROM recipes
        JOIN recipe_categories ON recipes.category_id = recipe_categories.id
        JOIN recipe_ingredients ON recipes.id = recipe_ingredients.recipe_id
        WHERE recipe_ingredients.ingredient_id IN ($placeholders)
        GROUP BY recipes.id
        ORDER BY matched_ingredients DESC, total_ingredients ASC
      ''', ingredientIds);
      print("Found ${result.length} recipes matching the selected ingredients");
      return result;
    } catch (e) {
      print("Error searching recipes by ingredients: $e");
      rethrow;
    }
  }

  Future<void> insertRecipeIngredients(
      int recipeId, List<Map<String, dynamic>> ingredients) async {
    try {
      Database db = await instance.database;
      await db.transaction((txn) async {
        // First, delete existing ingredients for this recipe
        await txn.delete('recipe_ingredients',
            where: 'recipe_id = ?', whereArgs: [recipeId]);

        // Then insert the new ingredients
        for (var ingredient in ingredients) {
          await txn.insert('recipe_ingredients', {
            'recipe_id': recipeId,
            'ingredient_id': ingredient['ingredient_id'],
            'quantity': ingredient['quantity'],
            'unit': ingredient['unit'],
            'order': ingredient['order'],
          });
        }
      });
      print("Inserted ${ingredients.length} ingredients for recipe $recipeId");
    } catch (e) {
      print("Error inserting recipe ingredients: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> queryStarredRecipes() async {
    try {
      Database db = await instance.database;
      var result = await db.rawQuery('''
      SELECT recipes.*, recipe_categories.name as category_name
      FROM recipes
      JOIN recipe_categories ON recipes.category_id = recipe_categories.id
      WHERE recipes.is_starred = 1
    ''');
      print("Queried ${result.length} starred recipes");
      return result;
    } catch (e) {
      print("Error querying starred recipes: $e");
      rethrow;
    }
  }

Future<List<Map<String, dynamic>>> getMealPlanEntriesForRecipe(int recipeId) async {
  final db = await database;
  return await db.query(
    'meal_plan',
    columns: ['id', 'day_of_week', 'meal_of_day'],
    where: 'recipe_id = ?',
    whereArgs: [recipeId],
  );
}
  Future<void> removeRecipeFromMealPlan(int recipeId) async {
  final db = await database;
  await db.delete(
    'meal_plan',
    where: 'recipe_id = ?',
    whereArgs: [recipeId],
  );
}
Future<void> removeMealPlanEntry(int entryId) async {
  final db = await database;
  await db.delete(
    'meal_plan',
    where: 'id = ?',
    whereArgs: [entryId],
  );
}
}
