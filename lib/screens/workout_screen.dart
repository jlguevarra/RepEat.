import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String selectedCategory = 'Upper Body';
  String selectedExercise = 'Push-ups';
  int targetSets = 3;
  int targetReps = 10;
  int completedReps = 0;
  bool isWorkoutStarted = false;

  final categories = {
    'Upper Body': ['Push-ups', 'Pull-ups', 'Shoulder Press'],
    'Lower Body': ['Squats', 'Lunges', 'Calf Raises'],
    'Core': ['Sit-ups', 'Plank', 'Leg Raises'],
    'Cardio': ['Jumping Jacks', 'Burpees'],
  };

  void _toggleWorkout() {
    setState(() {
      isWorkoutStarted = !isWorkoutStarted;
      if (!isWorkoutStarted) {
        completedReps = 0;
      }
    });
  }

  void _incrementRep() {
    if (isWorkoutStarted) {
      setState(() => completedReps++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exerciseList = categories[selectedCategory]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout Tracker"),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Category Selector
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

            // Exercise Selector
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

            // Target Set & Reps
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: targetSets.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target Sets',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) setState(() => targetSets = parsed);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: targetReps.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Reps per Set',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val);
                      if (parsed != null) setState(() => targetReps = parsed);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Rep Tracker
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

            // Start / End Workout
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

            // Simulated rep counting
            if (isWorkoutStarted)
              Center(
                child: OutlinedButton(
                  onPressed: _incrementRep,
                  child: const Text('Simulate Rep'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
