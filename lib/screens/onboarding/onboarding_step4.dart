import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../main_nav_screen.dart';

class OnboardingStep4 extends StatefulWidget {
  final int userId; // ✅ Added
  final String gender;
  final DateTime birthdate;
  final String bodyType;
  final String currentWeight;
  final String targetWeight;
  final String goal;
  final String sets;
  final String reps;

  const OnboardingStep4({
    super.key,
    required this.userId, // ✅ Added
    required this.gender,
    required this.birthdate,
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
  final TextEditingController injuryController = TextEditingController();

  // ✅ Predefined valid injuries
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

  Future<void> submitOnboardingData() async {
    final url = Uri.parse("http://192.168.100.79/repEatApi/save_onboarding.php");

    final data = {
      "user_id": widget.userId, // ✅ Pass real user ID here
      "gender": widget.gender,
      "birthdate": widget.birthdate.toIso8601String().split('T')[0],
      "body_type": widget.bodyType,
      "current_weight": widget.currentWeight,
      "target_weight": widget.targetWeight,
      "goal": widget.goal,
      "preferred_sets": widget.sets,
      "preferred_reps": widget.reps,
      "has_injury": hasInjury ? 1 : 0,
      "injury_details": hasInjury ? injuryController.text.trim().toLowerCase() : "",
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final result = jsonDecode(response.body);

      if (result['success']) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e')),
      );
    }
  }

  void _finishSetup() {
    if (hasInjury && injuryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your injury")),
      );
      return;
    }

    submitOnboardingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // ✅ Removes the back arrow
        title: const Text("Step 3: Injury Info"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Detected Body Type: ${widget.bodyType}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
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
                    injuryController.clear();
                  }
                });
              },
            ),

            if (hasInjury)
              DropdownButtonFormField<String>(
                value: injuryController.text.isNotEmpty ? injuryController.text : null,
                items: validInjuries.map((injury) {
                  return DropdownMenuItem(
                    value: injury,
                    child: Text(injury),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => injuryController.text = val);
                  }
                },
                decoration: const InputDecoration(
                  labelText: "Select Your Injury",
                  border: OutlineInputBorder(),
                ),
              ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finishSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Complete Setup"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
