import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'camera_workout_screen.dart'; // ✅ Import camera workout screen

class WorkoutScreen extends StatefulWidget {
  final int userId;

  const WorkoutScreen({super.key, required this.userId});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String selectedCategory = 'Upper Body';
  String selectedExercise = 'Push-ups';
  int completedReps = 0;
  bool isWorkoutStarted = false;

  final setsController = TextEditingController();
  final repsController = TextEditingController();

  final categories = {
    'Upper Body': ['Push-ups', 'Pull-ups', 'Shoulder Press'],
    'Lower Body': ['Squats', 'Lunges', 'Calf Raises'],
    'Core': ['Sit-ups', 'Plank', 'Leg Raises'],
    'Cardio': ['Jumping Jacks', 'Burpees'],
  };

  @override
  void dispose() {
    setsController.dispose();
    repsController.dispose();
    super.dispose();
  }

  void _toggleWorkout() {
    if (!isWorkoutStarted) {
      if (setsController.text.isEmpty || repsController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please input sets and reps')),
        );
        return;
      }
    }

    setState(() {
      isWorkoutStarted = !isWorkoutStarted;
      if (!isWorkoutStarted) {
        saveCameraWorkout();
        completedReps = 0;
      }
    });
  }

  void _incrementRep() {
    if (isWorkoutStarted) {
      setState(() => completedReps++);
    }
  }

  Future<void> saveCameraWorkout() async {
    final url = Uri.parse('http://192.168.0.11/repEatApi/camera_workout_screen.php');

    final data = {
      'user_id': 1, // 🔥 Replace with dynamic user id later
      'date': DateTime.now().toIso8601String().split('T')[0],
      'category': selectedCategory,
      'exercise_name': selectedExercise,
      'detected_reps': completedReps,
      'duration_seconds': 0,
      'accuracy_score': 0,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Workout saved successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Failed: ${result['message']}')),
          );
        }
      } else {
        throw Exception('❌ Failed to connect to API');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseList = categories[selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Remove back arrow
        title: const Text("Workout"), // ✅ Updated title
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Sets',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps per Set',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Center(
              child: Column(
                children: [
                  Text(
                    '$completedReps',
                    style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Reps Counted',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                icon: Icon(isWorkoutStarted ? Icons.stop : Icons.play_arrow),
                label: Text(isWorkoutStarted ? 'End Workout' : 'Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWorkoutStarted ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: _toggleWorkout,
              ),
            ),
            const SizedBox(height: 16),
            if (isWorkoutStarted)
              Center(
                child: OutlinedButton(
                  onPressed: _incrementRep,
                  child: const Text('Simulate Rep'),
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text('Use Camera for Rep Detection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraWorkoutScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
