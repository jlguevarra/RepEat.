import 'package:flutter/material.dart';
import 'camera_workout_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String selectedCategory = 'Upper Body';
  String selectedExercise = 'Push-ups';

  final categories = {
    'Upper Body': ['Push-ups', 'Pull-ups', 'Shoulder Press'],
    'Lower Body': ['Squats', 'Lunges', 'Calf Raises'],
    'Core': ['Sit-ups', 'Plank', 'Leg Raises'],
    'Cardio': ['Jumping Jacks', 'Burpees'],
  };

  @override
  Widget build(BuildContext context) {
    final exerciseList = categories[selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Workout"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: categories.keys
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    selectedCategory = val;
                    selectedExercise = categories[val]!.first;
                  });
                }
              },
              decoration: InputDecoration(
                labelText: 'Workout Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedExercise,
              items: exerciseList
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedExercise = val);
              },
              decoration: InputDecoration(
                labelText: 'Exercise',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Start Camera Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CameraWorkoutScreen(
                      userId: widget.userId,
                      category: selectedCategory,
                      exercise: selectedExercise,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
