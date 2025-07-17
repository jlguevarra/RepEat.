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
  String? originalGoal;
  String? originalSets;
  String? originalReps;

  bool isLoading = true;
  bool isSaving = false;
  bool isEditing = false;

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

    setsController.addListener(() {
      if (isEditing) setState(() {});
    });
    repsController.addListener(() {
      if (isEditing) setState(() {});
    });
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

    currentWeight = double.tryParse(prefs.getString('current_weight') ?? '') ?? 0;
    targetWeight = double.tryParse(prefs.getString('target_weight') ?? '') ?? 0;

    try {
      final response = await http.get(Uri.parse(
        'http://192.168.0.11/repEatApi/get_profile.php?user_id=$userId',
      ));
      final data = json.decode(response.body);

      if (data['success'] == true) {
        final profile = data['data'];

        if (currentWeight == 0) {
          currentWeight = double.tryParse(profile['current_weight'] ?? '0') ?? 0;
        }
        if (targetWeight == 0) {
          targetWeight = double.tryParse(profile['target_weight'] ?? '0') ?? 0;
        }

        _determineAllowedGoals();

        originalGoal = profile['goal'] ?? allowedGoals.first;
        selectedGoal = originalGoal;

        if (!allowedGoals.contains(selectedGoal)) {
          selectedGoal = allowedGoals.first;
        }

        originalSets = profile['preferred_sets'] ?? '';
        originalReps = profile['preferred_reps'] ?? '';

        setsController.text = originalSets!;
        repsController.text = originalReps!;
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

  bool get hasChanges {
    return selectedGoal != originalGoal ||
        setsController.text.trim() != originalSets ||
        repsController.text.trim() != originalReps;
  }

  Future<void> _saveData() async {
    setState(() => isSaving = true);

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.11/repEatApi/update_fitness_goals.php'),
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

        setState(() {
          originalGoal = selectedGoal;
          originalSets = setsController.text.trim();
          originalReps = repsController.text.trim();
          isEditing = false;
        });
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

  Future<void> _handleCancel() async {
    if (!hasChanges) {
      setState(() => isEditing = false);
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel changes?'),
        content: const Text('Any unsaved changes will be lost. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        selectedGoal = originalGoal;
        setsController.text = originalSets!;
        repsController.text = originalReps!;
        isEditing = false;
      });
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
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: _handleCancel,
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
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
            isEditing
                ? DropdownButtonFormField<String>(
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
            )
                : Text(selectedGoal!, style: const TextStyle(fontSize: 16)),
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
                        readOnly: !isEditing,
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
                        readOnly: !isEditing,
                        decoration: _inputDecoration(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            if (isEditing)
              Center(
                child: ElevatedButton(
                  onPressed: (!hasChanges || isSaving) ? null : _saveData,
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
