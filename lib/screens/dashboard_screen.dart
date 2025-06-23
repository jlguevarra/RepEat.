import 'package:flutter/material.dart';
import 'workout_screen.dart';
import 'meal_plan_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RepEat Dashboard'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Workout Summary
            _sectionCard(
              title: "Today's Workout Summary",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('125 Reps', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Last Exercise: Pull-Ups'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                      );
                    },
                    child: const Text('Start Workout'),
                  ),
                ],
              ),
            ),

            // Meal + Progress Row
            Row(
              children: [
                Expanded(
                  child: _sectionCard(
                    title: "Today's Meal Plan",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Breakfast:\nChicken Breast, Salmon'),
                        SizedBox(height: 8),
                        Text('1800 kcal   140g P   150g C   60g F'),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: null,
                          child: Text('View Full Meal Plan'),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _sectionCard(
                    title: "Weekly Progress",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("You're doing great!"),
                        const Text("Consider a protein boost today"),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [50, 70, 90, 80, 100, 120]
                              .map((val) => Container(
                            height: val.toDouble(),
                            width: 10,
                            color: Colors.deepPurple,
                          ))
                              .toList(),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text('S  M  T  W  T  F'),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Planner + Injury
            Row(
              children: [
                Expanded(
                  child: _simpleCard(
                    title: "Planner",
                    content: "Initial: 160 lb\nTarget: 180 lb",
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _simpleCard(
                    title: "Declaration of Injuries",
                    content: "Knee Injury\nSince Apr 10",
                    trailing: Switch(value: false, onChanged: (_) {}),
                  ),
                ),
              ],
            ),

            // Categories + Navigation
            Row(
              children: [
                Expanded(
                  child: _simpleCard(
                    title: "Per Categories\nand add Progression",
                    content: "",
                    child: Column(
                      children: [
                        _progressBar(0.6, Colors.deepPurple),
                        const SizedBox(height: 4),
                        _progressBar(0.4, Colors.orange),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _simpleCard(
                    title: "View Meal Plan",
                    content: "",
                    child:ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                        );
                      },
                      child: const Text('View Meal Plan'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _simpleCard({required String title, required String content, Widget? child, Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(content),
                if (child != null) ...[
                  const SizedBox(height: 8),
                  child,
                ]
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _progressBar(double value, Color color) {
    return LinearProgressIndicator(
      value: value,
      backgroundColor: Colors.grey.shade300,
      color: color,
      minHeight: 6,
    );
  }
}


//