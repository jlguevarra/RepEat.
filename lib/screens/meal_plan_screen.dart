import 'package:flutter/material.dart';

class MealPlanScreen extends StatelessWidget {
  final int userId;
  const MealPlanScreen({super.key, required this.userId});

  final meals = const [
    {
      'type': 'Breakfast',
      'items': ['Oatmeal with banana', 'Boiled egg', 'Green tea'],
      'calories': 400,
      'protein': 20,
      'carbs': 45,
      'fat': 10,
    },
    {
      'type': 'Lunch',
      'items': ['Grilled chicken', 'Brown rice', 'Steamed broccoli'],
      'calories': 600,
      'protein': 40,
      'carbs': 60,
      'fat': 15,
    },
    {
      'type': 'Snack',
      'items': ['Protein bar', 'Almonds'],
      'calories': 250,
      'protein': 15,
      'carbs': 20,
      'fat': 12,
    },
    {
      'type': 'Dinner',
      'items': ['Baked salmon', 'Quinoa', 'Mixed salad'],
      'calories': 550,
      'protein': 35,
      'carbs': 40,
      'fat': 20,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Remove back arrow
        title: const Text('Meal Plan'),   // ✅ Updated title
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: meals.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final meal = meals[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meal['type'] as String,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...List<Widget>.from((meal['items'] as List).map(
                        (item) => Text("• $item"),
                  )),
                  const SizedBox(height: 8),
                  Text(
                    "Calories: ${meal['calories']} kcal",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text("Protein: ${meal['protein']}g"),
                  Text("Carbs: ${meal['carbs']}g"),
                  Text("Fat: ${meal['fat']}g"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
