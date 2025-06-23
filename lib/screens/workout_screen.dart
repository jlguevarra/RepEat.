import 'package:flutter/material.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  String selectedExercise = 'Push-ups';
  int repCount = 0;
  bool isWorkoutStarted = false;

  final List<String> exercises = [
    'Push-ups',
    'Squats',
    'Sit-ups',
    'Lunges',
    'Pull-ups',
  ];

  void _toggleWorkout() {
    setState(() {
      isWorkoutStarted = !isWorkoutStarted;
      if (!isWorkoutStarted) {
        repCount = 0; // reset when ending workout
      }
    });
  }

  void _incrementRep() {
    if (isWorkoutStarted) {
      setState(() {
        repCount++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Workout Tracker"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Exercise selector
            DropdownButtonFormField<String>(
              value: selectedExercise,
              items: exercises
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => selectedExercise = val);
                }
              },
              decoration: InputDecoration(
                labelText: 'Select Exercise',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),

            // Rep counter
            Text(
              '$repCount',
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Reps Counted',
              style: TextStyle(fontSize: 18),
            ),

            const Spacer(),

            // Start/End workout button
            ElevatedButton.icon(
              icon: Icon(isWorkoutStarted ? Icons.stop : Icons.play_arrow),
              label: Text(isWorkoutStarted ? 'End Workout' : 'Start Workout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWorkoutStarted ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              onPressed: _toggleWorkout,
            ),

            const SizedBox(height: 16),

            // Simulated rep count trigger
            if (isWorkoutStarted)
              OutlinedButton(
                onPressed: _incrementRep,
                child: const Text('Simulate Rep'),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
