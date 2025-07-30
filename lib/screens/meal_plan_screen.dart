import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'recipe_details_screen.dart'; // Keep this import

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
  String timeFrame = 'day'; // 'day' or 'week'
  DateTime selectedDate = DateTime.now();
  final NumberFormat caloriesFormat = NumberFormat.decimalPattern();
  String? apiError;

  @override
  void initState() {
    super.initState();
    // Fetch user data AND previously saved meal plan
    initializeMealPlan();
  }

  // Step 1: Load user data and last saved meal plan
  Future<void> initializeMealPlan() async {
    setState(() {
      isLoading = true;
      apiError = null;
    });

    try {
      // First, fetch user data
      final userUrl = Uri.parse(
        'http://192.168.100.78/repEatApi/get_profile.php?user_id=${widget.userId}',
      );
      final userResponse = await http.get(userUrl);
      if (userResponse.statusCode == 200) {
        final jsonData = jsonDecode(userResponse.body);
        if (jsonData['success'] == true) {
          setState(() {
            userData = jsonData['data'];
          });
        } else {
          throw Exception("No user  ${jsonData['message']}");
        }
      } else {
        throw Exception("User fetch failed: ${userResponse.statusCode}");
      }

      // Then, fetch the last saved meal plan
      final mealPlanUrl = Uri.parse(
        'http://192.168.100.78/repEatApi/get_saved_meal_plan.php?user_id=${widget.userId}',
      );
      final mealResponse = await http.get(mealPlanUrl);
      if (mealResponse.statusCode == 200) {
        final mealData = jsonDecode(mealResponse.body);
        if (mealData['success'] == true && mealData['data'] != null) {
          final savedPlan = jsonDecode(mealData['data']['meal_plan']); // Parse JSON string
          setState(() {
            mealPlan = savedPlan;
            // Restore settings used to generate it
            timeFrame = mealData['data']['time_frame'] ?? 'day';
            if (mealData['data']['start_date'] != null) {
              selectedDate = DateFormat('yyyy-MM-dd').parse(mealData['data']['start_date']);
            }
          });
        }
      }
      // If no saved plan, just continue with mealPlan = null
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

  // Step 2: Generate new meal plan using Spoonacular
  Future<void> generateMealPlan() async {
    if (userData == null) return;

    setState(() {
      isGeneratingMeal = true;
      apiError = null;
    });

    try {
      // Extract user preferences
      String diet = userData!['diet_preference'] ?? '';
      String goal = userData!['goal'] ?? '';
      String allergies = userData!['allergies'] ?? '';

      // Prepare API parameters
      Map<String, String> queryParams = {
        'timeFrame': timeFrame,
        'targetCalories': mapGoalToCalories(goal).toString(),
        'diet': mapDietToSpoonacular(diet),
        'exclude': allergies,
        'apiKey': 'f9cc3b3cd30e4007bf4da738d79d9680',
      };

      if (timeFrame == 'week') {
        queryParams['startDate'] = DateFormat('yyyy-MM-dd').format(selectedDate);
      }

      queryParams.removeWhere((key, value) => value.isEmpty);

      final url = Uri.https(
        'api.spoonacular.com',
        '/mealplanner/generate',
        queryParams,
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        // Save to local state
        setState(() {
          mealPlan = jsonData;
        });

        // Save to server database
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

  // Step 3: Save generated meal plan to your server
  Future<void> _saveMealPlanToServer(dynamic mealPlanData) async {
    try {
      final url = Uri.parse('http://192.168.100.78/repEatApi/save_meal_plan.php');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userId,
          'time_frame': timeFrame,
          'start_date': timeFrame == 'week' ? DateFormat('yyyy-MM-dd').format(selectedDate) : null,
          'meal_plan': jsonEncode(mealPlanData), // Store as JSON string
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
    const dietMap = {
      'vegetarian': 'vegetarian',
      'vegan': 'vegan',
      'keto': 'ketogenic',
      'gluten-free': 'gluten free',
      'paleo': 'paleo',
      'mediterranean': 'mediterranean',
      'low carb': 'low carb',
      'dairy free': 'dairy free',
    };
    return dietMap[diet.toLowerCase()] ?? '';
  }

  int mapGoalToCalories(String goal) {
    const goalMap = {
      'weight loss': 1500,
      'extreme weight loss': 1200,
      'moderate weight loss': 1800,
      'muscle gain': 2500,
      'extreme muscle gain': 3000,
      'maintain weight': 2000,
    };
    return goalMap[goal.toLowerCase()] ?? 2000;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != selectedDate && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget buildMealCard(String mealType, dynamic mealData) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getMealIcon(mealType),
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mealType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
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
            if (mealData['readyInMinutes'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${mealData['readyInMinutes']} min',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            if (mealData['servings'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${mealData['servings']} servings',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecipeDetailsScreen(
                      recipeId: mealData['id'],
                      recipeTitle: mealData['title'],
                    ),
                  ),
                );
              },
              child: const Text('View Recipe Details'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getMealIcon(String mealType) {
    if (mealType.toLowerCase().contains('breakfast')) {
      return Icons.breakfast_dining;
    } else if (mealType.toLowerCase().contains('lunch')) {
      return Icons.lunch_dining;
    } else if (mealType.toLowerCase().contains('dinner')) {
      return Icons.dinner_dining;
    } else if (mealType.toLowerCase().contains('snack')) {
      return Icons.local_cafe;
    }
    return Icons.restaurant;
  }

  Widget _buildNutritionInfo() {
    if (mealPlan == null || mealPlan!['nutrients'] == null) {
      return const SizedBox();
    }
    final nutrients = mealPlan!['nutrients'];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nutrition Summary",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.deepPurple),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            apiError ?? 'An error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (mealPlan == null) {
                initializeMealPlan(); // Retry both user and meal plan
              } else {
                generateMealPlan();
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meal Plan"),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (mealPlan != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: isGeneratingMeal ? null : generateMealPlan,
              tooltip: 'Regenerate',
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : apiError != null
          ? _buildErrorWidget()
          : userData == null
          ? const Center(child: Text("No user data found"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Preferences Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your Preferences",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPreferenceRow("Diet", userData!['diet_preference'] ?? 'Not specified'),
                    _buildPreferenceRow("Goal", userData!['goal'] ?? 'Not specified'),
                    _buildPreferenceRow("Allergies", userData!['allergies']?.isNotEmpty == true
                        ? userData!['allergies']
                        : 'None'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'day',
                        label: Text('Daily'),
                        icon: Icon(Icons.calendar_view_day),
                      ),
                      ButtonSegment(
                        value: 'week',
                        label: Text('Weekly'),
                        icon: Icon(Icons.calendar_view_week),
                      ),
                    ],
                    selected: {timeFrame},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        timeFrame = newSelection.first;
                      });
                    },
                  ),
                  if (timeFrame == 'week')
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('MMM d').format(selectedDate),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Generate Button
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
                label: Text(
                  isGeneratingMeal
                      ? 'Generating...'
                      : 'Generate ${timeFrame == 'day' ? 'Daily' : 'Weekly'} Meal Plan',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Display Meal Plan if exists
            if (mealPlan != null) ...[
              Text(
                timeFrame == 'day'
                    ? "Your Daily Meal Plan"
                    : "Your Weekly Meal Plan (Starting ${DateFormat('MMM d').format(selectedDate)})",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (mealPlan!['meals'] != null)
                ...mealPlan!['meals'].map<Widget>((meal) {
                  return buildMealCard(meal['title'], meal);
                }).toList(),
              const SizedBox(height: 16),
              _buildNutritionInfo(),
            ] else
              const Center(
                child: Text(
                  "No meal plan generated yet. Tap 'Generate' to get started!",
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}