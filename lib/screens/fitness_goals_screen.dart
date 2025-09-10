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
  String? selectedGoal;
  String? originalGoal;
  bool isLoading = true;
  int? userId;
  double currentWeight = 0;
  double targetWeight = 0;
  final allGoals = [
    'Muscle Gain',
    'Weight Loss',
  ];
  List<String> allowedGoals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');
    if (userId == null) {
      _showCustomSnackBar('User ID not found. Please log in again.', false);
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
      } else {
        _showCustomSnackBar(data['message'] ?? 'Failed to load goals.', false);
      }
    } catch (e) {
      _showCustomSnackBar('Error loading goals: $e', false);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _determineAllowedGoals() {
    allowedGoals = [];
    if (targetWeight > currentWeight) {
      allowedGoals.add('Muscle Gain');
    } else if (targetWeight < currentWeight) {
      allowedGoals.add('Weight Loss');
    } else {
      allowedGoals.add('Maintain Weight');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.deepPurple,
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

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        title: const Text('Fitness Goals'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
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
                      Text(
                        selectedGoal ?? 'No goal set',
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}