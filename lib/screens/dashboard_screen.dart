import 'package:flutter/material.dart';
import 'meal_plan_screen.dart';
import 'workout_screen.dart';
import 'profile_screen.dart';
import 'calendar_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("RepEat Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _profileSection(),

            const SizedBox(height: 16),

            // Workout + Meal Plan Row
            Row(
              children: [
                Expanded(child: _workoutSummary(context)),
                const SizedBox(width: 12),
                Expanded(child: _mealPlanSummary(context)),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Section
            _progressSection(),

            const SizedBox(height: 16),

            // Quick Navigation
            _quickNavigation(context),
          ],
        ),
      ),
    );
  }

  Widget _profileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.deepPurple,
            child: Icon(Icons.person, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "John Doe",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("Goal: Muscle Gain"),
                Text(
                  "⚠️ Knee Injury Declared",
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _workoutSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Workout Summary",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Last: Push-ups\n3 Sets of 12 Reps"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkoutScreen()),
              );
            },
            child: const Text("Start Workout"),
          ),
        ],
      ),
    );
  }

  Widget _mealPlanSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Meal Plan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text("Calories: 1800 kcal\nProtein: 140g\nCarbs: 150g\nFat: 60g"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealPlanScreen()),
              );
            },
            child: const Text("View Meal Plan"),
          ),
        ],
      ),
    );
  }

  Widget _progressSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Progress",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [50, 80, 90, 70, 100, 60, 75].map((val) {
              return Container(
                width: 12,
                height: val.toDouble(),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('S'),
                Text('M'),
                Text('T'),
                Text('W'),
                Text('T'),
                Text('F'),
                Text('S'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickNavigation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Quick Navigation",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _navButton(Icons.fitness_center, "Workout", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                );
              }),
              _navButton(Icons.restaurant_menu, "Meal Plan", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MealPlanScreen()),
                );
              }),
              _navButton(Icons.calendar_today, "Calendar", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CalendarScreen()),
                );
              }),

              _navButton(Icons.person, "Profile", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }


  Widget _navButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.deepPurple),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    );
  }
}
