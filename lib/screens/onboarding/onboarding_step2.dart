import 'package:flutter/material.dart';
import 'onboarding_step3.dart'; // You’ll create this next

class OnboardingStep2 extends StatefulWidget {
  final String gender;
  final DateTime birthdate;

  const OnboardingStep2({
    super.key,
    required this.gender,
    required this.birthdate,
  });

  @override
  State<OnboardingStep2> createState() => _OnboardingStep2State();
}

class _OnboardingStep2State extends State<OnboardingStep2> {
  int? _selectedCurrentBody;
  int? _selectedTargetBody;

  final List<String> bodyImages = [
    'assets/bodies/body1.png',
    'assets/bodies/body2.png',
    'assets/bodies/body3.png',
    'assets/bodies/body4.png',
  ];

  void _goToNextStep() {
    if (_selectedCurrentBody == null || _selectedTargetBody == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingStep3(
          gender: widget.gender,
          birthdate: widget.birthdate,
          currentBodyIndex: _selectedCurrentBody!,
          targetBodyIndex: _selectedTargetBody!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2: Select Body Type'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Current Body Type:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _imagePicker(
              selectedIndex: _selectedCurrentBody,
              onTap: (index) => setState(() => _selectedCurrentBody = index),
            ),
            const SizedBox(height: 24),
            const Text(
              "Your Target Body Type:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _imagePicker(
              selectedIndex: _selectedTargetBody,
              onTap: (index) => setState(() => _selectedTargetBody = index),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_selectedCurrentBody != null && _selectedTargetBody != null)
                    ? _goToNextStep
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Next"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePicker({required int? selectedIndex, required Function(int) onTap}) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: bodyImages.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return GestureDetector(
            onTap: () => onTap(index),
            child: Container(
              width: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                bodyImages[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
