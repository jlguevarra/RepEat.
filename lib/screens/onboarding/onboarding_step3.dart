import 'package:flutter/material.dart';
import 'onboarding_step4.dart';

class OnboardingStep3 extends StatefulWidget {
  final int userId; // ✅ Added
  final String gender;
  final DateTime birthdate;

  const OnboardingStep3({
    super.key,
    required this.userId, // ✅ Added
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

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      double height = double.parse(_heightController.text) / 100; // convert to meters
      double weight = double.parse(_currentWeightController.text);
      double bmi = weight / (height * height);

      String bodyType;
      if (bmi < 18.5) {
        bodyType = 'Underweight';
      } else if (bmi < 25) {
        bodyType = 'Normal';
      } else {
        bodyType = 'Overweight';
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingStep4(
            userId: widget.userId, // ✅ Pass userId forward
            gender: widget.gender,
            birthdate: widget.birthdate,
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

  String? _validateNumber(String? value, String label, {double? min, double? max}) {
    if (value == null || value.isEmpty) return 'Required';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Enter a valid number';
    if (min != null && parsed < min) return '$label must be ≥ $min';
    if (max != null && parsed > max) return '$label must be ≤ $max';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Step 2: Your Fitness Info'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                validator: (value) => _validateNumber(value, 'Height', min: 100, max: 250),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _currentWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Current Weight (kg)'),
                validator: (value) => _validateNumber(value, 'Current weight', min: 30, max: 300),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
                validator: (value) {
                  final baseValidation = _validateNumber(value, 'Target weight', min: 30, max: 300);
                  if (baseValidation != null) return baseValidation;
                  if (value == _currentWeightController.text) {
                    return 'Target weight must be different from current weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: const InputDecoration(labelText: 'Fitness Goal'),
                items: _goals.map((goal) => DropdownMenuItem(value: goal, child: Text(goal))).toList(),
                onChanged: (value) => setState(() => _selectedGoal = value),
                validator: (value) => value == null ? 'Please select a goal' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _setsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Preferred Sets'),
                      validator: (value) => _validateNumber(value, 'Sets', min: 1, max: 10),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps per Set'),
                      validator: (value) => _validateNumber(value, 'Reps', min: 1, max: 100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
