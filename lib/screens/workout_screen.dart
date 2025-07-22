import 'package:flutter/material.dart';
import 'camera_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final Map<String, List<String>> _dumbbellExercises = {
    'Biceps': ['Dumbbell Curls', 'Hammer Curls', 'Concentration Curls'],
    'Triceps': ['Tricep Kickbacks', 'Overhead Extensions'],
    'Shoulders': ['Shoulder Press', 'Lateral Raise', 'Front Raise'],
    'Chest': ['Dumbbell Bench Press', 'Dumbbell Fly'],
    'Back': ['Dumbbell Rows', 'Reverse Fly'],
    'Legs': ['Goblet Squats', 'Dumbbell Lunges', 'Dumbbell Deadlifts'],
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
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _dumbbellExercises.keys.length,
        itemBuilder: (context, index) {
          final category = _dumbbellExercises.keys.elementAt(index);
          final exercises = _dumbbellExercises[category]!;

          return ExpansionTile(
            title: Text(
              category,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            children: exercises.map((exercise) {
              return ListTile(
                title: Text(exercise),
                trailing: const Icon(Icons.fitness_center),
                onTap: () => _startWorkout(category, exercise),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
