import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  final String recipeTitle;
  final int userId; // Added userId to interact with backend

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
    required this.userId,
  });

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  Map<String, dynamic>? recipeDetails;
  bool isLoading = true;
  bool isFavorite = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecipeDetails();
    _checkIfFavorite(); // Check if this recipe is already favorited
  }

  Future<void> _fetchRecipeDetails() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.https(
        'api.spoonacular.com',
        '/recipes/${widget.recipeId}/information',
        {
          'includeNutrition': 'true',
          'apiKey': 'f9cc3b3cd30e4007bf4da738d79d9680',
        },
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recipeDetails = data;
        });
      } else {
        throw Exception('Failed to load recipe details: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// Check if the current recipe is already in user's favorites
  Future<void> _checkIfFavorite() async {
    try {
      final url = Uri.parse(
        'http://192.168.1.252/repEatApi/get_favorites.php?user_id=${widget.userId}',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List favorites = data['data'];
          final bool found = favorites.any((f) => f['recipe_id'] == widget.recipeId);

          if (mounted) {
            setState(() {
              isFavorite = found;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Check favorite error: $e");
    }
  }

  /// Toggle favorite status (add or remove)
  Future<void> _toggleFavorite() async {
    final String imageUrl = recipeDetails?['image'] ?? '';

    try {
      if (isFavorite) {
        // Remove from favorites
        final url = Uri.parse('http://192.168.1.252/repEatApi/remove_favorite.php');
        final response = await http.delete(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'recipe_id': widget.recipeId,
          }),
        );

        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          setState(() {
            isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites')),
          );
        }
      } else {
        // Add to favorites
        final url = Uri.parse('http://192.168.1.252/repEatApi/add_favorite.php');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': widget.userId,
            'recipe_id': widget.recipeId,
            'recipe_title': widget.recipeTitle,
            'recipe_image': imageUrl,
          }),
        );

        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          setState(() {
            isFavorite = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.deepPurple),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionFact(String label, dynamic value, String unit) {
    final String valueStr = value is num
        ? value.toStringAsFixed(value is int ? 0 : 1)
        : '0';

    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Text(
            valueStr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipeTitle),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image
            if (recipeDetails?['image'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipeDetails!['image'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            // Recipe Information Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recipe Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recipeDetails?['readyInMinutes'] != null)
                      _buildInfoRow(
                        Icons.timer,
                        'Ready in ${recipeDetails!['readyInMinutes']} minutes',
                      ),
                    if (recipeDetails?['servings'] != null)
                      _buildInfoRow(
                        Icons.people,
                        'Serves ${recipeDetails!['servings']}',
                      ),
                    if (recipeDetails?['healthScore'] != null)
                      _buildInfoRow(
                        Icons.health_and_safety,
                        'Health Score: ${recipeDetails!['healthScore']}/100',
                      ),
                    if (recipeDetails?['dishTypes'] != null &&
                        recipeDetails!['dishTypes'].isNotEmpty)
                      _buildInfoRow(
                        Icons.restaurant_menu,
                        'Type: ${recipeDetails!['dishTypes'].join(', ')}',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Ingredients
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ingredients',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recipeDetails?['extendedIngredients'] != null)
                      ...recipeDetails!['extendedIngredients']
                          .map<Widget>((ingredient) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.circle, size: 8),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ingredient['original']?.toString() ?? 'No info',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Instructions
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (recipeDetails?['instructions'] != null &&
                        recipeDetails!['instructions'].isNotEmpty)
                      Html(
                        data: recipeDetails!['instructions'],
                        style: {
                          "body": Style(
                            margin: Margins.zero,
                            padding: HtmlPaddings.zero,
                            fontSize: FontSize(16.0),
                          ),
                        },
                      )
                    else if (recipeDetails?['analyzedInstructions'] != null &&
                        recipeDetails!['analyzedInstructions'].isNotEmpty)
                      ...recipeDetails!['analyzedInstructions'][0]['steps']
                          .map<Widget>((step) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${step['number']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(step['step'] ?? 'No description'),
                              if (step['ingredients'] != null &&
                                  step['ingredients'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: step['ingredients']
                                        .map<Widget>((ing) {
                                      return Chip(
                                        label: Text(ing['name']?.toString() ?? 'Unknown'),
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList()
                    else
                      const Text('No instructions available'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Nutrition Facts
            if (recipeDetails?['nutrition'] != null)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nutrition Facts',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (recipeDetails!['nutrition']['calories'] != null)
                              _buildNutritionFact(
                                'Calories',
                                recipeDetails!['nutrition']['calories'],
                                'kcal',
                              ),
                            if (recipeDetails!['nutrition']['protein'] != null)
                              _buildNutritionFact(
                                'Protein',
                                recipeDetails!['nutrition']['protein'],
                                'g',
                              ),
                            if (recipeDetails!['nutrition']['fat'] != null)
                              _buildNutritionFact(
                                'Fat',
                                recipeDetails!['nutrition']['fat'],
                                'g',
                              ),
                            if (recipeDetails!['nutrition']['carbs'] != null)
                              _buildNutritionFact(
                                'Carbs',
                                recipeDetails!['nutrition']['carbs'],
                                'g',
                              ),
                          ],
                        ),
                      ),
                      if (recipeDetails?['nutrition']['nutrients'] != null)
                        ...recipeDetails!['nutrition']['nutrients']
                            .where((nutrient) =>
                        nutrient['name'] != 'Calories' &&
                            nutrient['name'] != 'Protein' &&
                            nutrient['name'] != 'Fat' &&
                            nutrient['name'] != 'Carbohydrates')
                            .take(8)
                            .map<Widget>((nutrient) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    nutrient['name']?.toString() ?? 'Unknown',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '${nutrient['amount']?.toStringAsFixed(nutrient['amount'] is int ? 0 : 1) ?? '0'} ${nutrient['unit']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}