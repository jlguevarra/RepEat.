import 'package:flutter/material.dart';
import 'onboarding_step4.dart';

class OnboardingStep3 extends StatefulWidget {
  final String gender;
  final DateTime birthdate;
  final int currentBodyIndex;
  final int targetBodyIndex;

  const OnboardingStep3({
    super.key,
    required this.gender,
    required this.birthdate,
    required this.currentBodyIndex,
    required this.targetBodyIndex,
  });

  @override
  State<OnboardingStep3> createState() => _OnboardingStep3State();
}

class _OnboardingStep3State extends State<OnboardingStep3> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentWeightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _setsController = TextEditingController(text: "3");
  final TextEditingController _repsController = TextEditingController(text: "12");

  String? _selectedGoal;
  final List<String> _goals = [
    'Muscle Gain',
    'Weight Loss',
    'Endurance',
    'General Fitness'
  ];

  void _goToStep4() {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingStep4(
            gender: widget.gender,
            birthdate: widget.birthdate,
            currentBodyIndex: widget.currentBodyIndex,
            targetBodyIndex: widget.targetBodyIndex,
            currentWeight: _currentWeightController.text.trim(),
            targetWeight: _targetWeightController.text.trim(),
            goal: _selectedGoal!,
            sets: _setsController.text.trim(),
            reps: _repsController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3: Your Fitness Info'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _currentWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Current Weight (kg)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Target Weight (kg)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedGoal,
                decoration: const InputDecoration(labelText: 'Fitness Goal'),
                items: _goals
                    .map((goal) => DropdownMenuItem(value: goal, child: Text(goal)))
                    .toList(),
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
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _repsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Reps per Set'),
                      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _goToStep4,
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
