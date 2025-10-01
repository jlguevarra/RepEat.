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

  // MODIFIED: Use your new Google Gemini API key.
  static const String geminiApiKey = 'AIzaSyC3IhY-aAkXfPKeteU0WKyQCJmr5TRsAuw'; // <-- PASTE YOUR FRESH KEY HERE

  @override
  void initState() {
    super.initState();
    initializeMealPlan();
  }

  // MODIFIED: This function is now updated to launch the Gemini-powered ChatScreen.
  void _navigateToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userId: widget.userId,
          userData: userData,
          apiKey: geminiApiKey, // Use the new Gemini key
          apiType: 'gemini',     // Specify the API type as 'gemini'
        ),
      ),
    );
  }

  // ... (All other code in this file remains exactly the same)

  Future<void> initializeMealPlan() async {
    setState(() {
      isLoading = true;
      apiError = null;
    });

    try {
      final userUrl = Uri.parse(
          'http://192.168.100.11/repEatApi/get_profile.php?user_id=${widget.userId}');
      final userResponse = await http.get(userUrl).timeout(const Duration(seconds: 10));
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
          'http://192.168.100.11/repEatApi/get_saved_meal_plan.php?user_id=${widget.userId}');
      final mealResponse = await http.get(mealPlanUrl).timeout(const Duration(seconds: 10));
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
          apiError = "Failed to load data. Please check your connection.";
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
        'apiKey': 'f9cc3b3cd30e4007bf4da738d79d9680', // Your Spoonacular API Key
      };

      if (timeFrame == 'week') {
        queryParams['startDate'] =
            DateFormat('yyyy-MM-dd').format(selectedDate);
      }

      queryParams.removeWhere((key, value) => value.isEmpty);

      final url =
      Uri.https('api.spoonacular.com', '/mealplanner/generate', queryParams);

      final response = await http.get(url).timeout(const Duration(seconds: 20));
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
        apiError = "Failed to generate plan. The API might be busy. Please try again later.";
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
      final url = Uri.parse('http://192.168.100.11/repEatApi/save_meal_plan.php');
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

  IconData _getMealIcon(String mealType) {
    if (mealType.toLowerCase().contains('breakfast')) return Icons.breakfast_dining;
    if (mealType.toLowerCase().contains('lunch')) return Icons.lunch_dining;
    if (mealType.toLowerCase().contains('dinner')) return Icons.dinner_dining;
    return Icons.restaurant;
  }

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

  String _getMealTypeByIndex(int index) {
    if (index == 0) return 'Breakfast';
    if (index == 1) return 'Lunch';
    if (index == 2) return 'Dinner';
    return 'Meal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Meal Plan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (mealPlan != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 28),
              onPressed: isGeneratingMeal ? null : generateMealPlan,
              tooltip: 'Regenerate Plan',
            ),
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
      body: RefreshIndicator(
        onRefresh: initializeMealPlan,
        color: Colors.deepPurple,
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
            : apiError != null
            ? _buildErrorState(apiError!)
            : userData == null
            ? const Center(child: Text("No user data found"))
            : ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (mealPlan != null) ...[
              Text(
                timeFrame == 'day'
                    ? "Your Daily Meal Plan"
                    : "Your Weekly Meal Plan",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 8),
              _buildNutritionSummary(),
              const SizedBox(height: 16),
              ..._extractMealsFromMealPlan()
                  .asMap()
                  .entries
                  .map<Widget>((entry) {
                final index = entry.key;
                final meal = entry.value;
                return _buildMealCard(_getMealTypeByIndex(index), meal);
              })
                  .toList(),
            ] else
              _buildIntroState(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToChatScreen,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
        label: const Text(
          "AI Assistant",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildIntroState() {
    String goal = userData?['goal']?.replaceAll('_', ' ') ?? 'Not set';
    String diet = userData?['diet_preference'] ?? 'Not set';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.deepPurple, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Ready for Your Personal Meal Plan?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              "We'll generate a delicious meal plan tailored to your preferences.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildPreferenceChip('Goal: ${toTitleCase(goal)}', Icons.flag),
            const SizedBox(height: 8),
            _buildPreferenceChip('Diet: ${toTitleCase(diet)}', Icons.local_dining),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: isGeneratingMeal ? null : generateMealPlan,
              icon: isGeneratingMeal
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.auto_awesome),
              label: Text(isGeneratingMeal ? 'Generating...' : 'Generate My Plan'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 20),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.deepPurple)),
        ],
      ),
    );
  }

  Widget _buildMealCard(String mealType, dynamic mealData) {
    final String imageUrl = "https://spoonacular.com/recipeImages/${mealData['id']}-${'312x231'}.${mealData['imageType']}";
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const SizedBox(height: 150, child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.deepPurple,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Chip(
                  label: Text(mealType, style: const TextStyle(color: Colors.white)),
                  backgroundColor: Colors.black.withOpacity(0.6),
                  avatar: Icon(_getMealIcon(mealType), color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mealData['title'] ?? 'No title',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    Text('${mealData['readyInMinutes'] ?? '?'} min', style: TextStyle(color: Colors.grey[800])),
                    const SizedBox(width: 16),
                    Icon(Icons.people_outline, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 4),
                    Text('${mealData['servings'] ?? '?'} servings', style: TextStyle(color: Colors.grey[800])),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('View Recipe', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionSummary() {
    if (mealPlan == null || mealPlan!['nutrients'] == null) return const SizedBox();

    final nutrients = mealPlan!['nutrients'];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "${caloriesFormat.format(nutrients['calories'])} kcal",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.deepPurple),
            ),
            const Text("Total Estimated Calories", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientIndicator("Protein", "${nutrients['protein']}g", Colors.blue),
                _buildNutrientIndicator("Carbs", "${nutrients['carbohydrates']}g", Colors.orange),
                _buildNutrientIndicator("Fat", "${nutrients['fat']}g", Colors.pink),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off, color: Colors.redAccent, size: 60),
          const SizedBox(height: 16),
          const Text("Something went wrong", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
              onPressed: initializeMealPlan,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white
              )
          )
        ]),
      ),
    );
  }

  String toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }
}