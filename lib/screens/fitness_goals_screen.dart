import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FitnessGoalsScreen extends StatefulWidget {
  const FitnessGoalsScreen({super.key});

  @override
  State<FitnessGoalsScreen> createState() => _FitnessGoalsScreenState();
}

class _FitnessGoalsScreenState extends State<FitnessGoalsScreen> {
  final setsController = TextEditingController();
  final repsController = TextEditingController();

  String? selectedGoal;
  bool isLoading = true;
  bool isSaving = false;

  int? userId;
  double currentWeight = 0;
  double targetWeight = 0;

  final allGoals = [
    'Muscle Gain',
    'Weight Loss',
    'Endurance',
    'General Fitness',
  ];

  List<String> allowedGoals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found. Please log in again.')),
      );
      Navigator.pop(context);
      return;
    }

    // Read weights from SharedPreferences if available
    currentWeight = double.tryParse(prefs.getString('current_weight') ?? '') ?? 0;
    targetWeight = double.tryParse(prefs.getString('target_weight') ?? '') ?? 0;

    try {
      final response = await http.get(Uri.parse(
        'http://192.168.100.78/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];

        // Fallback if SharedPreferences values are not set yet
        if (currentWeight == 0) {
          currentWeight = double.tryParse(profile['current_weight'] ?? '0') ?? 0;
        }
        if (targetWeight == 0) {
          targetWeight = double.tryParse(profile['target_weight'] ?? '0') ?? 0;
        }

        _determineAllowedGoals();

        selectedGoal = profile['goal'] ?? allowedGoals.first;

        if (!allowedGoals.contains(selectedGoal)) {
          selectedGoal = allowedGoals.first;
        }

        setsController.text = profile['preferred_sets'] ?? '';
        repsController.text = profile['preferred_reps'] ?? '';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to load goals.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _determineAllowedGoals() {
    allowedGoals = ['Endurance', 'General Fitness'];
    if (targetWeight > currentWeight) {
      allowedGoals.insert(0, 'Muscle Gain');
    }
    if (targetWeight < currentWeight) {
      allowedGoals.insert(0, 'Weight Loss');
    }
  }

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.78/repEatApi/update_fitness_goals.php'),
        body: {
          'user_id': userId.toString(),
          'goal': selectedGoal,
          'sets': setsController.text.trim(),
          'reps': repsController.text.trim(),
        },
      );

      final data = json.decode(response.body);

      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Goals updated.')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Failed to update goals.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Goals'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fitness Goal',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedGoal,
              items: allowedGoals.map((goal) {
                return DropdownMenuItem(
                  value: goal,
                  child: Text(goal),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => selectedGoal = val);
              },
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferred Sets',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: setsController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Preferred Reps',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: repsController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                ),
                child: isSaving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text('Save', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
