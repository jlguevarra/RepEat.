import 'package:flutter/material.dart';
import 'onboarding_step3.dart';

class OnboardingStep1 extends StatefulWidget {
  final int userId;

  const OnboardingStep1({super.key, required this.userId});

  @override
  State<OnboardingStep1> createState() => _OnboardingStep1State();
}

class _OnboardingStep1State extends State<OnboardingStep1> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedGender;
  DateTime? _birthDate;

  void _nextStep() {
    if (!_formKey.currentState!.validate()) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birthdate')),
      );
      return;
    }

    final now = DateTime.now();
    final age = now.year - _birthDate!.year;
    if (_birthDate!.isAfter(now) || age < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid birthdate (10+ years old)')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingStep3(
          userId: widget.userId, // ✅ Pass userId to step 3
          gender: _selectedGender!,
          birthdate: _birthDate!,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Step 1: Personal Info'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                value: _selectedGender,
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() => _selectedGender = value);
                },
                validator: (value) =>
                value == null ? 'Please select your gender' : null,
              ),
              const SizedBox(height: 24),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Birthdate',
                  border: OutlineInputBorder(),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _birthDate == null
                        ? 'Not selected'
                        : '${_birthDate!.month}/${_birthDate!.day}/${_birthDate!.year}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: _pickDate,
                    child: const Text('Pick Date'),
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
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
