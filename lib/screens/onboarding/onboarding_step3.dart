import 'package:flutter/material.dart';
import 'onboarding_step4.dart';

class OnboardingStep3 extends StatefulWidget {
  final int userId;
  final String gender;
  final DateTime birthdate;

  const OnboardingStep3({
    super.key,
    required this.userId,
    required this.gender,
    required this.birthdate,
  });

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(text: "3");
  final TextEditingController _repsController = TextEditingController(text: "12");

  String? _selectedGoal;
  final List<String> _goals = [
    'Muscle Gain',
    'Weight Loss',
    'Endurance',
    'General Fitness',
  ];

  String? _bmiCategory;

  // Custom Snackbar method (Added for consistency)
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


  void _updateBMICategory() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_currentWeightController.text);
    if (height != null && height > 0 && weight != null && weight > 0) {
      final hMeters = height / 100;
      final bmi = weight / (hMeters * hMeters);

      String category;
      if (bmi < 18.5) {
        category = 'Underweight';
      } else if (bmi < 25) {
        category = 'Normal';
      } else if (bmi < 30) {
        category = 'Overweight';
      } else {
        category = 'Obese';
      }

      setState(() {
        _bmiCategory = category;
      });
    } else {
      setState(() {
        _bmiCategory = null;
      });
    }
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      String bodyType = _bmiCategory ?? 'Unknown';

      // Navigate to next step
      if (mounted) { // Check if widget is still mounted before navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingStep4(
              userId: widget.userId,
              gender: widget.gender,
              birthdate: widget.birthdate,
              height: _heightController.text,
              bodyType: bodyType,
              currentWeight: _currentWeightController.text,
              targetWeight: _targetWeightController.text,
              goal: _selectedGoal!,
              sets: _setsController.text,
              reps: _repsController.text,
            ),
          ),
        );
      }
    }
  }

  String? _validateNumber(String? value, String label, {double? min, double? max}) {
    if (value == null || value.isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (min != null && parsed < min) return '$label must be ≥ $min';
    if (max != null && parsed > max) return '$label must be ≤ $max';
    return null;
  }

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_updateBMICategory);
    _currentWeightController.addListener(_updateBMICategory);
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateBMICategory); // Explicitly remove listeners
    _currentWeightController.removeListener(_updateBMICategory);
    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Your Fitness Info'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Explicitly set app bar text/icon color
        elevation: 0, // Remove shadow for a flatter look
      ),
      body: SafeArea( // Wrap content in SafeArea
        child: SingleChildScrollView( // Allow scrolling if needed
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center, // Changed icon to fitness related
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Title
                Text(
                  "Let's Get Fit!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),

                // Subtitle
                Text(
                  "Tell us about your goals and current stats",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // Height Field
                TextFormField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'e.g., 175',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
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
                    prefixIcon: Icon(
                      Icons.height,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  validator: (value) => _validateNumber(value, 'Height', min: 100, max: 250),
                ),
                const SizedBox(height: 20),

                // Current Weight Field
                TextFormField(
                  controller: _currentWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Current Weight (kg)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'e.g., 70',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
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
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  validator: (value) => _validateNumber(value, 'Current weight', min: 30, max: 300),
                ),
                const SizedBox(height: 20),

                // Target Weight Field
                TextFormField(
                  controller: _targetWeightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Target Weight (kg)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    hintText: 'e.g., 75',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
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
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  validator: (value) {
                    final baseValidation = _validateNumber(value, 'Target weight', min: 30, max: 300);
                    if (baseValidation != null) return baseValidation;

                    final current = double.tryParse(_currentWeightController.text);
                    final target = double.tryParse(value ?? '');
                    if (current == null || target == null) return 'Invalid weight values';

                    if (target == current) {
                      return 'Target weight must be different from current weight';
                    }

                    if (_selectedGoal == 'Weight Loss' && target > current) {
                      return 'Target must be less than current (Weight Loss)';
                    }

                    if (_selectedGoal == 'Muscle Gain' && target < current) {
                      return 'Target must be more than current (Muscle Gain)';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // BMI Category Display
                if (_bmiCategory != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepPurple.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _bmiCategory == 'Normal' ? Icons.check_circle : Icons.info,
                          color: _bmiCategory == 'Normal' ? Colors.green : Colors.deepPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BMI Category: $_bmiCategory',
                          style: TextStyle(
                            color: Colors.deepPurple.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Fitness Goal Dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Fitness Goal',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    filled: true,
                    fillColor: Colors.white,
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
                    prefixIcon: Icon(
                      Icons.flag_circle_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                  value: _selectedGoal,
                  items: _goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
                  onChanged: (value) {
                    setState(() => _selectedGoal = value);
                  },
                  validator: (value) => value == null ? 'Please select a goal' : null,
                ),
                const SizedBox(height: 20),

                // Sets and Reps Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Preferred Sets',
                          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                          hintText: 'e.g., 3',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
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
                          prefixIcon: Icon(
                            Icons.exposure, // Icon for sets
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        validator: (value) => _validateNumber(value, 'Sets', min: 1, max: 10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Reps per Set',
                          labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                          hintText: 'e.g., 12',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
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
                          prefixIcon: Icon(
                            Icons.repeat, // Icon for reps
                            color: Colors.deepPurple.shade700,
                          ),
                        ),
                        validator: (value) => _validateNumber(value, 'Reps', min: 1, max: 100),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40), // Space before button

                // Next Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade800,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
}