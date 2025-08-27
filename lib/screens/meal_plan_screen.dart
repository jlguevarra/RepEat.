import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'recipe_details_screen.dart';
import 'favorites_screen.dart';
import 'chat_screen.dart';

class MealPlanScreen extends StatefulWidget {
  final int userId;
  const MealPlanScreen({super.key, required this.userId});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? mealPlan;
  bool isLoading = true;
  bool isGeneratingMeal = false;
  String timeFrame = 'day';
  DateTime selectedDate = DateTime.now();
  final NumberFormat caloriesFormat = NumberFormat.decimalPattern();
  String? apiError;

  static const String openRouterApiKey = 'sk-or-your-openrouter-api-key';

  @override
  void initState() {
    super.initState();
    initializeMealPlan();
  }

  Future<void> initializeMealPlan() async {
    setState(() {
      isLoading = true;
      apiError = null;
    });

    try {
      final userUrl = Uri.parse(
          'http://localhost/repEatApi/get_profile.php?user_id=${widget.userId}');
      final userResponse = await http.get(userUrl);
      if (userResponse.statusCode == 200) {
        final jsonData = jsonDecode(userResponse.body);
        if (jsonData['success'] == true) {
          setState(() {
            userData = jsonData['data'];
          });
        } else {
          throw Exception("No user data: ${jsonData['message']}");
        }
      } else {
        throw Exception("User fetch failed: ${userResponse.statusCode}");
      }

      final mealPlanUrl = Uri.parse(
          'http://localhost/repEatApi/get_saved_meal_plan.php?user_id=${widget.userId}');
      final mealResponse = await http.get(mealPlanUrl);
      if (mealResponse.statusCode == 200) {
        final mealData = jsonDecode(mealResponse.body);
        if (mealData['success'] == true && mealData['data'] != null) {
          final savedPlan = jsonDecode(mealData['data']['meal_plan']);
          setState(() {
            mealPlan = savedPlan;
            timeFrame = mealData['data']['time_frame'] ?? 'day';
            if (mealData['data']['start_date'] != null) {
              selectedDate =
                  DateFormat('yyyy-MM-dd').parse(mealData['data']['start_date']);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          apiError = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> generateMealPlan() async {
    if (userData == null) return;

    setState(() {
      isGeneratingMeal = true;
      apiError = null;
    });

    try {
      String diet = userData!['diet_preference'] ?? '';
      String goal = userData!['goal'] ?? '';
      String allergies = userData!['allergies'] ?? '';

      Map<String, String> queryParams = {
        'timeFrame': timeFrame,
        'targetCalories': mapGoalToCalories(goal).toString(),
        'diet': mapDietToSpoonacular(diet),
        'exclude': allergies,
        'apiKey': 'f9cc3b3cd30e4007bf4da738d79d9680',
      };

      if (timeFrame == 'week') {
        queryParams['startDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDate);
      }

      queryParams.removeWhere((key, value) => value.isEmpty);

      final url =
      Uri.https('api.spoonacular.com', '/mealplanner/generate', queryParams);

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          mealPlan = jsonData;
        });
        await _saveMealPlanToServer(jsonData);
      } else {
        throw Exception("API error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() {
        apiError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isGeneratingMeal = false;
        });
      }
    }
  }

  Future<void> _saveMealPlanToServer(dynamic mealPlanData) async {
    try {
      final url = Uri.parse('http://localhost/repEatApi/save_meal_plan.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'time_frame': timeFrame,
          'start_date': timeFrame == 'week'
              ? DateFormat('yyyy-MM-dd').format(selectedDate)
              : null,
          'meal_plan': jsonEncode(mealPlanData),
        }),
      );

      final result = jsonDecode(response.body);
      if (result['success'] != true) {
        debugPrint("Failed to save meal plan: ${result['message']}");
      }
    } catch (e) {
      debugPrint("Error saving meal plan: $e");
    }
  }

  String mapDietToSpoonacular(String diet) {
    final String normalized = diet.toLowerCase().replaceAll('-', ' ').trim();
    const Map<String, String> dietMap = {
      'none': '',
      'vegetarian': 'vegetarian',
      'vegan': 'vegan',
      'keto': 'ketogenic',
      'paleo': 'paleo',
      'mediterranean': 'mediterranean',
      'low carb': 'low-carb',
      'high protein': 'high-protein',
    };
    return dietMap[normalized] ?? '';
  }

  int mapGoalToCalories(String goal) {
    final String normalized = goal.toLowerCase().trim();
    const Map<String, int> goalMap = {
      'weight loss': 1500,
      'muscle gain': 2500,
      'endurance': 2200,
      'general fitness': 2000,
    };
    return goalMap[normalized] ?? 2000;
  }

  Widget buildMealCard(String mealType, dynamic mealData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getMealIcon(mealType), color: Colors.deepPurple),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mealType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mealData['title'] ?? 'No title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsScreen(
                        recipeId: mealData['id'],
                        recipeTitle: mealData['title'],
                        userId: widget.userId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu, color: Colors.white),
                label: const Text(
                  'View Recipe Details',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    if (mealType.toLowerCase().contains('breakfast')) return Icons.breakfast_dining;
    if (mealType.toLowerCase().contains('lunch')) return Icons.lunch_dining;
    if (mealType.toLowerCase().contains('dinner')) return Icons.dinner_dining;
    return Icons.restaurant;
  }

  Widget _buildNutritionInfo() {
    if (mealPlan == null || mealPlan!['nutrients'] == null) return const SizedBox();

    final nutrients = mealPlan!['nutrients'];
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nutrition Summary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildNutritionRow("Calories", "${caloriesFormat.format(nutrients['calories'])} kcal"),
            _buildNutritionRow("Protein", "${nutrients['protein']}g"),
            _buildNutritionRow("Fat", "${nutrients['fat']}g"),
            _buildNutritionRow("Carbohydrates", "${nutrients['carbohydrates']}g"),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.deepPurple)),
        ],
      ),
    );
  }

  List<dynamic> _extractMealsFromMealPlan() {
    if (mealPlan == null) return [];

    if (timeFrame == 'day') {
      // Organize meals into breakfast, lunch, dinner categories only
      final List<dynamic> meals = mealPlan!['meals'] ?? [];
      final Map<String, dynamic> categorizedMeals = {};

      // Define meal types in order
      final List<String> mealTypes = ['breakfast', 'lunch', 'dinner'];

      // Categorize meals by type
      for (var meal in meals) {
        final String mealTitle = meal['title']?.toLowerCase() ?? '';
        String mealType = 'other';

        // Determine meal type based on title keywords
        if (mealTitle.contains('breakfast')) {
          mealType = 'breakfast';
        } else if (mealTitle.contains('lunch')) {
          mealType = 'lunch';
        } else if (mealTitle.contains('dinner')) {
          mealType = 'dinner';
        } else if (mealTitle.contains('snack') || mealTitle.contains('morning') ||
            mealTitle.contains('evening') || mealTitle.contains('afternoon')) {
          // Skip snacks, assign to nearest meal type
          if (mealTitle.contains('morning') || mealTitle.contains('breakfast')) {
            mealType = 'breakfast';
          } else if (mealTitle.contains('afternoon') || mealTitle.contains('lunch')) {
            mealType = 'lunch';
          } else if (mealTitle.contains('evening') || mealTitle.contains('dinner')) {
            mealType = 'dinner';
          }
        } else {
          // For meals without clear indicators, assign based on position
          int index = meals.indexOf(meal);
          if (index % 3 == 0) {
            mealType = 'breakfast';
          } else if (index % 3 == 1) {
            mealType = 'lunch';
          } else {
            mealType = 'dinner';
          }
        }

        // Only add if not already assigned to this category
        if (!categorizedMeals.containsKey(mealType)) {
          categorizedMeals[mealType] = meal;
        }
      }

      // Ensure all categories have meals, fill with empty if needed
      List<dynamic> result = [];
      for (String type in mealTypes) {
        if (categorizedMeals.containsKey(type)) {
          result.add(categorizedMeals[type]);
        } else {
          // Add placeholder for missing meal type
          result.add({
            'title': '$type (Not specified)',
            'id': null,
            'image': null,
          });
        }
      }

      return result;
    } else {
      final List<dynamic> allMeals = [];
      final weekData = mealPlan!['week'];
      if (weekData == null) return [];
      weekData.values.forEach((day) {
        final List meals = day['meals'] ?? [];
        allMeals.addAll(meals);
      });
      return allMeals;
    }
  }

  void _navigateToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: widget.userId,
          userData: userData,
          apiKey: openRouterApiKey,
          apiType: 'openrouter',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text("Meal Plan", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(userId: widget.userId),
                ),
              );
            },
            tooltip: 'My Favorites',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : apiError != null
          ? _buildErrorState(apiError!)
          : userData == null
          ? const Center(child: Text("No user data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: FilledButton.icon(
                onPressed: isGeneratingMeal ? null : generateMealPlan,
                icon: isGeneratingMeal
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.restaurant_menu),
                label: Text(isGeneratingMeal
                    ? 'Generating...'
                    : 'Generate ${timeFrame == 'day' ? 'Daily' : 'Weekly'} Meal Plan'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (mealPlan != null) ...[
              Text(
                timeFrame == 'day'
                    ? "Your Daily Meal Plan"
                    : "Your Weekly Meal Plan",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ..._extractMealsFromMealPlan()
                  .map<Widget>((meal) => buildMealCard(
                  _getMealTypeFromMealData(meal), meal))
                  .toList(),
              _buildNutritionInfo(),
            ] else
              _buildEmptyState(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToChatScreen,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.chat, color: Colors.white, size: 26),
        label: const Text(
          "AI Assistant",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // This is the key fix - ensure we return the correct meal type strings
  String _getMealTypeFromMealData(dynamic meal) {
    final String mealTitle = meal['title']?.toLowerCase() ?? '';

    // Debug print to see what's being processed
    print("Processing meal title: $mealTitle");

    // First check if we can identify it directly
    if (mealTitle.contains('breakfast')) {
      print("Identified as Breakfast");
      return 'Breakfast';
    }
    if (mealTitle.contains('lunch')) {
      print("Identified as Lunch");
      return 'Lunch';
    }
    if (mealTitle.contains('dinner')) {
      print("Identified as Dinner");
      return 'Dinner';
    }

    // Check for related terms
    if (mealTitle.contains('morning') || mealTitle.contains('breakfast')) {
      print("Identified as Breakfast (morning)");
      return 'Breakfast';
    }
    if (mealTitle.contains('afternoon') || mealTitle.contains('lunch')) {
      print("Identified as Lunch (afternoon)");
      return 'Lunch';
    }
    if (mealTitle.contains('evening') || mealTitle.contains('dinner')) {
      print("Identified as Dinner (evening)");
      return 'Dinner';
    }

    // If still not identified, return a default but log it
    print("Default case - returning 'Meal'");
    return 'Meal'; // This should not happen with proper categorization
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 12),
        const Text("Something went wrong",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: const [
          Icon(Icons.fastfood_outlined, color: Colors.grey, size: 48),
          SizedBox(height: 12),
          Text("No meal plan yet. Tap 'Generate' to get started!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ]),
      ),
    );
  }
}