import 'package:flutter/material.dart';
import 'onboarding_step5.dart';

class OnboardingStep4 extends StatefulWidget {
  final int userId;
  final String gender;
  final DateTime birthdate;
  final String height; // ✅ added
  final String bodyType;
  final String currentWeight;
  final String targetWeight;
  final String goal;
  final String sets;
  final String reps;

  const OnboardingStep4({
    super.key,
    required this.userId,
    required this.gender,
    required this.birthdate,
    required this.height, // ✅ added
    required this.bodyType,
    required this.currentWeight,
    required this.targetWeight,
    required this.goal,
    required this.sets,
    required this.reps,
  });

  @override
  State<OnboardingStep4> createState() => _OnboardingStep4State();
}

class _OnboardingStep4State extends State<OnboardingStep4> {
  bool hasInjury = false;
  String? selectedInjury;

  final List<String> validInjuries = [
    "Knee Pain",
    "Back Pain",
    "Shoulder Injury",
    "Ankle Sprain",
    "Wrist Pain",
    "Elbow Pain",
    "Neck Strain",
    "Hip Pain",
  ];

  void _nextStep() {
    if (hasInjury && (selectedInjury == null || selectedInjury!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your injury")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingStep5(
          userId: widget.userId,
          gender: widget.gender,
          birthdate: widget.birthdate,
          height: widget.height, // ✅ pass height
          bodyType: widget.bodyType,
          currentWeight: widget.currentWeight,
          targetWeight: widget.targetWeight,
          goal: widget.goal,
          sets: widget.sets,
          reps: widget.reps,
          hasInjury: hasInjury,
          injuryDetails: hasInjury ? selectedInjury! : "",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Injury Info"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Do you have any injuries?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text("Yes, I have an injury"),
              activeColor: Colors.deepPurple,
              value: hasInjury,
              onChanged: (val) {
                setState(() {
                  hasInjury = val;
                  if (!hasInjury) {
                    selectedInjury = null;
                  }
                });
              },
            ),
            if (hasInjury) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedInjury,
                items: validInjuries.map((injury) {
                  return DropdownMenuItem(
                    value: injury,
                    child: Text(injury),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => selectedInjury = val);
                },
                decoration: const InputDecoration(
                  labelText: "Select Your Injury",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  "Next",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
