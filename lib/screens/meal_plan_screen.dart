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

  static const String openRouterApiKey =
      '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';

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
          'http://192.168.100.78/repEatApi/get_profile.php?user_id=${widget.userId}');
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
          'http://192.168.100.78/repEatApi/get_saved_meal_plan.php?user_id=${widget.userId}');
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
      final url = Uri.parse('http://192.168.100.78/repEatApi/save_meal_plan.php');
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
      'high protein': 'high-protein',
      'low carb': 'low-carb',
      'low fat': 'low-fat',
      'low sodium': 'low-sodium',
      'dairy free': 'dairy-free',
    };
    return dietMap[normalized] ?? '';
  }

  int mapGoalToCalories(String goal) {
    final String normalized = goal.toLowerCase().trim();
    const Map<String, int> goalMap = {
      'muscle gain': 2500,
      'weight loss': 1500,
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
                    mealType,
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

  /// ✅ Extract meals from API response (keep original order)
  List<dynamic> _extractMealsFromMealPlan() {
    if (mealPlan == null) return [];

    if (timeFrame == 'day') {
      return List.from(mealPlan!['meals'] ?? []);
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

  /// ✅ Assign meal type by index
  String _getMealTypeByIndex(int index) {
    if (index == 0) return 'Breakfast';
    if (index == 1) return 'Lunch';
    if (index == 2) return 'Dinner';
    return 'Meal';
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
        title: const Text(
          "Meal Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // ✅ Make title white
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // ✅ Makes icons and back button white
        elevation: 0, // Optional: Flat style like profile screen
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
                  .asMap()
                  .entries
                  .map<Widget>((entry) {
                final index = entry.key;
                final meal = entry.value;
                return buildMealCard(_getMealTypeByIndex(index), meal);
              })
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
