import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_html/flutter_html.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final int recipeId;
  final String recipeTitle;

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    required this.recipeTitle,
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
    _checkIfFavorite();
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
        setState(() {
          recipeDetails = jsonDecode(response.body);
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

  Future<void> _checkIfFavorite() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {
        isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 1),
      ),
    );
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
    final String valueStr = value is num ? value.toStringAsFixed(value is int ? 0 : 1) : '0';

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
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Basic Info
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
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
                        'Health score: ${recipeDetails!['healthScore']}/100',
                      ),
                    if (recipeDetails?['dishTypes'] != null &&
                        recipeDetails!['dishTypes'].isNotEmpty)
                      _buildInfoRow(
                        Icons.restaurant,
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
                padding: const EdgeInsets.all(12),
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
                                  ingredient['original']?.toString() ?? 'No ingredient info',
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
                padding: const EdgeInsets.all(12),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(step['step'] ?? 'No step description'),
                              if (step['ingredients'] != null &&
                                  step['ingredients'].isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 4,
                                    children: step['ingredients']
                                        .map<Widget>((ingredient) {
                                      return Chip(
                                        label: Text(ingredient['name']?.toString() ?? 'Unknown'),
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
                  padding: const EdgeInsets.all(12),
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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