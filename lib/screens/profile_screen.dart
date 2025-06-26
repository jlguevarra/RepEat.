import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final nameController = TextEditingController(text: "John Doe");
  final currentWeightController = TextEditingController(text: "160");
  final targetWeightController = TextEditingController(text: "180");
  final setsController = TextEditingController(text: "3");
  final repsController = TextEditingController(text: "12");

  String selectedGoal = 'Muscle Gain';
  bool hasInjury = false;
  String injuryDetails = '';

  final goals = ['Muscle Gain', 'Weight Loss', 'Endurance', 'General Fitness'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Planner'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _sectionTitle('Personal Information'),
            _textInput('Full Name', nameController),
            const SizedBox(height: 16),

            _sectionTitle('Body Stats'),
            _textInput('Current Weight (lbs)', currentWeightController),
            const SizedBox(height: 12),
            _textInput('Target Weight (lbs)', targetWeightController),
            const SizedBox(height: 16),

            _sectionTitle('Fitness Goal'),
            DropdownButtonFormField<String>(
              value: selectedGoal,
              items: goals
                  .map((goal) => DropdownMenuItem(
                  value: goal, child: Text(goal)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedGoal = value);
              },
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 16),

            _sectionTitle('Workout Preferences'),
            Row(
              children: [
                Expanded(child: _textInput('Sets', setsController)),
                const SizedBox(width: 16),
                Expanded(child: _textInput('Reps per Set', repsController)),
              ],
            ),
            const SizedBox(height: 16),

            _sectionTitle('Declaration of Injury'),
            SwitchListTile(
              title: const Text('Do you have an injury?'),
              value: hasInjury,
              activeColor: Colors.deepPurple,
              onChanged: (val) {
                setState(() => hasInjury = val);
              },
            ),
            if (hasInjury)
              _textInput('Injury Details', TextEditingController(text: injuryDetails)),

            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                ),
                onPressed: () {
                  // Save functionality (connect to API later)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Saved')),
                  );
                },
                child: const Text('Save Profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepPurple),
    );
  }

  Widget _textInput(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(label: label),
    );
  }

  InputDecoration _inputDecoration({String? label}) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
