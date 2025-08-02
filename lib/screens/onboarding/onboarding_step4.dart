import 'package:flutter/material.dart';
import 'onboarding_step5.dart';

class OnboardingStep4 extends StatefulWidget {
  final int userId;
  final String gender;
  final DateTime birthdate;
  final String height;
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
    required this.height,
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

  // Custom Snackbar method
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

  void _nextStep() {
    if (hasInjury && (selectedInjury == null || selectedInjury!.isEmpty)) {
      _showCustomSnackBar("Please select your injury", false);
      return;
    }

    // Navigate to next step
    if (mounted) { // Check if widget is still mounted before navigation
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnboardingStep5(
            userId: widget.userId,
            gender: widget.gender,
            birthdate: widget.birthdate,
            height: widget.height,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade50, // Softer background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Injury Info"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white, // Explicitly set app bar text/icon color
        elevation: 0, // Remove shadow for a flatter look
      ),
      body: SafeArea( // Wrap content in SafeArea
        child: SingleChildScrollView( // Allow scrolling if needed
          padding: const EdgeInsets.all(24),
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
                    hasInjury ? Icons.healing : Icons.favorite, // Dynamic icon
                    size: 50,
                    color: hasInjury
                        ? Colors.deepPurple.shade800
                        : Colors.red.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Title
              Text(
                hasInjury ? "Tell Us About Your Injury" : "Any Injuries?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple.shade900,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              Text(
                hasInjury
                    ? "This helps us recommend safe exercises."
                    : "Let us know if you have any current injuries.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Injury Question Switch
              SwitchListTile(
                title: Text(
                  "I have an injury",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade800,
                  ),
                ),
                subtitle: Text(
                  hasInjury
                      ? "Please select the injury below"
                      : "Turn on if you have any injuries",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                activeColor: Colors.deepPurple.shade700,
                activeTrackColor: Colors.deepPurple.shade200,
                inactiveThumbColor: Colors.grey[400],
                inactiveTrackColor: Colors.grey[300],
                value: hasInjury,
                onChanged: (val) {
                  setState(() {
                    hasInjury = val;
                    if (!hasInjury) {
                      selectedInjury = null;
                    }
                  });
                },
                secondary: Icon(
                  hasInjury ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  color: hasInjury ? Colors.deepPurple.shade700 : Colors.green,
                ),
              ),
              const SizedBox(height: 20),

              // Injury Selection Dropdown (if injury is selected)
              if (hasInjury) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Select Your Injury",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
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
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.deepPurple.shade700, width: 2),
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Please select an injury' : null,
                      ),
                    ],
                  ),
                ),
              ],
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
                    "Next",
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
    );
  }
}