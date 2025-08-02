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

  // Custom Snackbar method - Improved Design
  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return; // Guard against state changes if widget is disposed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!isEditing || !hasChanges) return true;
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false); // Updated SnackBar
      if (mounted) Navigator.pop(context);
      return;
    }
    currentWeight = double.tryParse(prefs.getString('current_weight') ?? '') ?? 0;
    targetWeight = double.tryParse(prefs.getString('target_weight') ?? '') ?? 0;
    try {
      final response = await http.get(Uri.parse(
        'http://192.168.100.78/repEatApi/get_profile.php?user_id=$userId',
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
        _showCustomSnackBar(data['message'] ?? 'Failed to load goals.', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Error loading goals: $e', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => isLoading = false);
      }
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
    if (setsController.text.trim().isEmpty || repsController.text.trim().isEmpty) {
      _showCustomSnackBar('Sets and Reps cannot be empty.', false); // Updated SnackBar
      return;
    }

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
        _showCustomSnackBar(data['message'] ?? 'Goals updated successfully!', true); // Updated SnackBar
        if (mounted) { // Check if mounted before setState
          setState(() {
            originalGoal = selectedGoal;
            originalSets = setsController.text.trim();
            originalReps = repsController.text.trim();
            isEditing = false;
          });
        }
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to update goals.', false); // Updated SnackBar
      }
    } catch (e) {
      _showCustomSnackBar('Network error. Please try again.', false); // Updated SnackBar
    } finally {
      if (mounted) { // Check if mounted before setState
        setState(() => isSaving = false);
      }
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
    if (result == true && mounted) {
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
        backgroundColor: Colors.deepPurple, // Match app bar color
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Loading Fitness Goals...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.deepPurple.shade50, // Softer background - Improved Design
        appBar: AppBar(
          title: const Text('Fitness Goals'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _onWillPop()) {
                if (context.mounted) Navigator.pop(context);
              }
            },
          ),
          actions: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: _handleCancel,
                tooltip: 'Cancel',
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    isEditing = true;
                  });
                },
                tooltip: 'Edit',
              ),
          ],
        ),
        body: SafeArea( // Improved Design
          child: SingleChildScrollView( // Improved Design
            padding: const EdgeInsets.all(16), // Improved Design
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Improved Design
              children: [
                // Header Section - Improved Design
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Your Fitness Goals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set your workout preferences and objectives',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // Fitness Goal Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Fitness Goal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                          decoration: _inputDecoration(), // Improved Design
                          validator: (value) =>
                          value == null || value.isEmpty ? 'Please select a goal' : null,
                        )
                            : Text(
                          selectedGoal ?? 'No goal set',
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Sets & Reps Section - Improved Design (Card)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.settings_outlined,
                              color: Colors.deepPurple.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Workout Preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Preferred Sets',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: setsController,
                                    keyboardType: TextInputType.number,
                                    readOnly: !isEditing,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: _inputDecoration().copyWith( // Improved Design
                                      hintText: isEditing ? 'e.g., 3' : null,
                                    ),
                                    validator: (value) {
                                      if (isEditing && (value == null || value.isEmpty)) {
                                        return 'Required';
                                      }
                                      if (isEditing &&
                                          (int.tryParse(value!) == null || int.parse(value) <= 0)) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: repsController,
                                    keyboardType: TextInputType.number,
                                    readOnly: !isEditing,
                                    style: const TextStyle(color: Colors.black87),
                                    decoration: _inputDecoration().copyWith( // Improved Design
                                      hintText: isEditing ? 'e.g., 12' : null,
                                    ),
                                    validator: (value) {
                                      if (isEditing && (value == null || value.isEmpty)) {
                                        return 'Required';
                                      }
                                      if (isEditing &&
                                          (int.tryParse(value!) == null || int.parse(value) <= 0)) {
                                        return 'Enter a valid number';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button (only visible when editing) - Improved Design
                if (isEditing)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (!hasChanges || isSaving) ? null : _saveData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: isSaving
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Improved Input Decoration - Better Design Consistency
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
      ),
    );
  }

  @override
  void dispose() {
    setsController.removeListener(() {});
    repsController.removeListener(() {});
    setsController.dispose();
    repsController.dispose();
    super.dispose();
  }
}