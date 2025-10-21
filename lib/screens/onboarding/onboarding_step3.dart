import 'package:flutter/material.dart';
import 'onboarding_step4.dart'; // Make sure this path is correct

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

  String? _selectedGoal;
  final List<String> _allGoals = [
    'Muscle Gain - Lean',
    'Muscle Gain - Bulk',
    'Weight Loss',
  ];
  late List<String> _allowedGoals;

  String? _bmiCategory;
  String? _recommendedBmiCategory;

  void _showCustomSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
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
        duration: const Duration(seconds: 5),
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
      String recommendation;

      if (bmi < 18.5) {
        category = 'Underweight';
        recommendation = 'Normal';
      } else if (bmi < 25) {
        category = 'Normal';
        recommendation = 'Maintain';
      } else if (bmi < 30) {
        category = 'Overweight';
        recommendation = 'Normal';
      } else {
        category = 'Obese';
        recommendation = 'Normal';
      }

      setState(() {
        _bmiCategory = category;
        _recommendedBmiCategory = recommendation;
      });
    } else {
      setState(() {
        _bmiCategory = null;
        _recommendedBmiCategory = null;
      });
    }
  }

  void _updateAllowedGoals() {
    final currentStr = _currentWeightController.text;
    final targetStr = _targetWeightController.text;
    final heightStr = _heightController.text;

    final current = double.tryParse(currentStr);
    final target = double.tryParse(targetStr);
    final height = double.tryParse(heightStr);

    List<String> newAllowedGoals;

    const double shortStatureThresholdCm = 160.0;

    if (current == null || target == null || current == target) {
      newAllowedGoals = List.from(_allGoals);
    } else if (target > current) {
      if (height != null && height < shortStatureThresholdCm) {
        newAllowedGoals = ['Muscle Gain - Lean'];
      } else {
        final difference = target - current;
        if (difference > 5) {
          newAllowedGoals = ['Muscle Gain - Bulk'];
        } else {
          newAllowedGoals = ['Muscle Gain - Lean'];
        }
      }
    } else {
      newAllowedGoals = ['Weight Loss'];
    }

    setState(() {
      _allowedGoals = newAllowedGoals;
      if (_selectedGoal != null && !_allowedGoals.contains(_selectedGoal)) {
        _selectedGoal = null;
      }
      if (_allowedGoals.length == 1) {
        _selectedGoal = _allowedGoals.first;
      }
    });
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_selectedGoal == null) {
        _showCustomSnackBar('Please select a fitness goal.', false);
        return;
      }

      String bodyType = _bmiCategory ?? 'Unknown';

      if (mounted) {
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

  // ✅ MODIFIED: This function now validates target weight against height
  String? _validateTargetWeight(String? value) {
    // 1. Basic number validation
    final baseValidation = _validateNumber(value, 'Target weight', min: 30, max: 300);
    if (baseValidation != null) return baseValidation;

    // 2. Get other values needed for context
    final currentStr = _currentWeightController.text;
    final heightStr = _heightController.text;

    // Don't run complex validation if other fields are empty
    if (currentStr.isEmpty || heightStr.isEmpty) return null;

    final current = double.tryParse(currentStr);
    final target = double.tryParse(value ?? '');
    final height = double.tryParse(heightStr);

    // Check if parsing failed
    if (current == null || target == null || height == null) return 'Invalid inputs';

    // 3. Original logic checks
    if (target == current) {
      return 'Target must be different';
    }

    final double percentageDifference = ((target - current).abs() / current) * 100;
    const double unreasonableThresholdPercent = 40.0;
    if (percentageDifference > unreasonableThresholdPercent) {
      return 'Change is too extreme';
    }

    // 4. ✅ NEW: Panel's "Bulk" logic validation
    const double shortStatureThresholdCm = 160.0;
    const double bulkDifferenceKg = 5.0; // The threshold for "bulk"

    bool isGainingWeight = target > current;
    bool isShortStature = height < shortStatureThresholdCm;
    bool isBulkAttempt = (target - current) > bulkDifferenceKg;

    if (isGainingWeight && isShortStature && isBulkAttempt) {
      return 'Bulking not advised for this height.';
    }

    // 5. All checks passed
    return null;
  }

  // ✅ ADDED: New function to re-validate form when height changes
  void _revalidateForm() {
    _formKey.currentState?.validate();
  }

  @override
  void initState() {
    super.initState();
    _allowedGoals = List.from(_allGoals);

    _heightController.addListener(_updateBMICategory);
    _heightController.addListener(_updateAllowedGoals);
    _heightController.addListener(_revalidateForm); // ✅ ADDED listener

    _currentWeightController.addListener(_updateBMICategory);
    _currentWeightController.addListener(_updateAllowedGoals);
    _currentWeightController.addListener(_revalidateForm); // ✅ ADDED listener

    _targetWeightController.addListener(_updateAllowedGoals);
  }

  @override
  void dispose() {
    _heightController.removeListener(_updateBMICategory);
    _heightController.removeListener(_updateAllowedGoals);
    _heightController.removeListener(_revalidateForm); // ✅ ADDED listener
    _currentWeightController.removeListener(_updateBMICategory);
    _currentWeightController.removeListener(_updateAllowedGoals);
    _currentWeightController.removeListener(_revalidateForm); // ✅ ADDED listener
    _targetWeightController.removeListener(_updateAllowedGoals);

    _heightController.dispose();
    _currentWeightController.dispose();
    _targetWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Your Fitness Info',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            // ✅ ADDED: This makes validation more responsive
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 50,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "Let's Get Fit!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tell us about your goals and current stats",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _heightController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Height (cm)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    prefixIcon: Icon(
                      Icons.height,
                      color: Colors.deepPurple.shade700,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.deepPurple.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.deepPurple.shade700, width: 2)),
                  ),
                  validator: (value) =>
                      _validateNumber(value, 'Height', min: 100, max: 250),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _currentWeightController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Current Weight (kg)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    prefixIcon: Icon(
                      Icons.monitor_weight_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.deepPurple.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.deepPurple.shade700, width: 2)),
                  ),
                  validator: (value) => _validateNumber(
                      value, 'Current weight',
                      min: 30, max: 300),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _targetWeightController,
                  keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Target Weight (kg)',
                    labelStyle: TextStyle(color: Colors.deepPurple.shade700),
                    prefixIcon: Icon(
                      Icons.flag_outlined,
                      color: Colors.deepPurple.shade700,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: Colors.deepPurple.shade200)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.deepPurple.shade700, width: 2)),
                  ),
                  // ✅ The validator function is now much smarter
                  validator: _validateTargetWeight,
                ),
                const SizedBox(height: 10),
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
                          _bmiCategory == 'Normal'
                              ? Icons.check_circle
                              : Icons.info,
                          color: _bmiCategory == 'Normal'
                              ? Colors.green
                              : Colors.deepPurple,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Current BMI Status: $_bmiCategory',
                          style: TextStyle(
                            color: Colors.deepPurple.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_recommendedBmiCategory != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.recommend,
                          color: Colors.green.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recommended Status: $_recommendedBmiCategory',
                          style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                DropdownButtonFormField<String?>(
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
                  items: _allowedGoals
                      .map((goal) =>
                      DropdownMenuItem(value: goal, child: Text(goal)))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _selectedGoal = value);
                  },
                  validator: (value) =>
                  value == null ? 'Please select a goal' : null,
                ),
                const SizedBox(height: 40),
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