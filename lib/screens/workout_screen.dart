import 'package:flutter/material.dart';
import 'camera_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Map<String, List<Map<String, String>>> _dumbbellExercises = {
    'Biceps': [
      {'name': 'Dumbbell Curls', 'image': 'assets/images/biceps.png'},
      {'name': 'Hammer Curls', 'image': 'assets/images/biceps.png'},
      {'name': 'Concentration Curls', 'image': 'assets/images/biceps.png'},
    ],
    'Triceps': [
      {'name': 'Tricep Kickbacks', 'image': 'assets/images/biceps.png'},
      {'name': 'Overhead Extensions', 'image': 'assets/images/biceps.png'},
    ],
    'Shoulders': [
      {'name': 'Shoulder Press', 'image': 'assets/images/biceps.png'},
      {'name': 'Lateral Raise', 'image': 'assets/images/biceps.png'},
      {'name': 'Front Raise', 'image': 'assets/images/biceps.png'},
    ],
    'Chest': [
      {'name': 'Dumbbell Bench Press', 'image': 'assets/images/biceps.png'},
      {'name': 'Dumbbell Fly', 'image': 'assets/images/biceps.png'},
    ],
    'Back': [
      {'name': 'Dumbbell Rows', 'image': 'assets/images/biceps.png'},
      {'name': 'Reverse Fly', 'image': 'assets/images/biceps.png'},
    ],
    'Legs': [
      {'name': 'Goblet Squats', 'image': 'assets/images/biceps.png'},
      {'name': 'Dumbbell Lunges', 'image': 'assets/images/biceps.png'},
      {'name': 'Dumbbell Deadlifts', 'image': 'assets/images/biceps.png'},
    ],
  };

  void _startWorkout(String category, String exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CameraWorkoutScreen(
          userId: widget.userId,
          category: category,
          exercise: exercise,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dumbbell Workouts"),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _dumbbellExercises.entries.expand((entry) {
          final category = entry.key;
          final exercises = entry.value;

          return [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                category,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            ...exercises.map((exercise) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Image.asset(
                    exercise['image']!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    exercise['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _startWorkout(category, exercise['name']!),
                ),
              );
            }).toList()
          ];
        }).toList(),
      ),
    );
  }
}
