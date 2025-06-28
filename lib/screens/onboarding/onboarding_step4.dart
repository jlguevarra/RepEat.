import 'package:flutter/material.dart';
import '../../main_nav_screen.dart'; // ✅ Use your main navigation shell

class OnboardingStep4 extends StatefulWidget {
  final String gender;
  final DateTime birthdate;
  final int currentBodyIndex;
  final int targetBodyIndex;
  final String currentWeight;
  final String targetWeight;
  final String goal;
  final String sets;
  final String reps;

  const OnboardingStep4({
    super.key,
    required this.gender,
    required this.birthdate,
    required this.currentBodyIndex,
    required this.targetBodyIndex,
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

  void _finishSetup() {
    // 🧠 You can save or send onboarding data here

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Setup completed!')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Step 4: Injury Info"),
        backgroundColor: Colors.deepPurple,
        automaticallyImplyLeading: false, // ⛔ Hide back arrow to avoid going back
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
              onChanged: (val) => setState(() => hasInjury = val),
            ),
            if (hasInjury)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: injuryController,
                  decoration: const InputDecoration(
                    labelText: "Injury Details (e.g. knee pain)",
                    border: OutlineInputBorder(),
                  ),
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
